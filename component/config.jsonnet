local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.group_sync_operator;

local addCredentialRef(cred) = function(config, provider)
  if std.objectHas(config, provider) then
    config {
      [provider]+: {
        credentialsSecret: cred,
      },
    }
  else
    config;

local parseProvider(k, p) =
  { name: p } +
  if std.objectHas(params.sync[k].providers[p], 'credentials') then
    std.foldl(addCredentialRef({
                name: 'groupsync-credentials-%s-%s' % [ k, p ],
                namespace: params.namespace,
              }),
              std.objectFields(params.sync[k].providers[p]),
              com.makeMergeable(params.sync[k].providers[p]) + {
                credentials:: {},
              })
  else
    com.makeMergeable(params.sync[k].providers[p]);

local groupSyncs = [
  if !std.objectHas(params.sync[k], 'providers') then
    error 'GroupSync needs to have at least one provider'
  else
    {
      apiVersion: 'redhatcop.redhat.io/v1alpha1',
      kind: 'GroupSync',
      metadata: {
        name: k,
        namespace: params.namespace,
      },
      spec: {
        providers: [
          parseProvider(k, p)
          for p in std.objectFields(params.sync[k].providers)
        ],
      },
    }
  for k in std.objectFields(params.sync)
];

local credentials = std.flattenArrays(
  [
    if !std.objectHas(params.sync[k], 'providers') then
      error 'GroupSync needs to have at least one provider'
    else
      [
        kube.Secret('groupsync-credentials-%s-%s' % [ k, p ]) {
          type: 'Opaque',
          metadata+: {
            namespace: params.namespace,
          },
        } + com.makeMergeable(params.sync[k].providers[p].credentials)
        for p in std.objectFields(params.sync[k].providers)
        if std.objectHas(params.sync[k].providers[p], 'credentials')
      ]
    for k in std.objectFields(params.sync)
  ]
);

{
  [if std.length(groupSyncs) > 0 then '02_groupsync']: groupSyncs,
  [if std.length(credentials) > 0 then '02_credentials']: credentials,
}
