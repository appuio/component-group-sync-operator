local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.group_sync_operator;
//
local addCredentialNamespace(config, provider) =
  if std.objectHas(config[provider], 'credentialsSecret') then
    config {
      [provider]+: {
        credentialsSecret+: {
          namespace: params.namespace,
        },
      },
    }
  else
    config;

local parseProvider(p) = std.foldl(addCredentialNamespace, std.objectFields(p), com.makeMergeable(p));

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
          { name: p } + parseProvider(params.sync[k].providers[p])
          for p in std.objectFields(params.sync[k].providers)
        ],
      },
    }
  for k in std.objectFields(params.sync)
];

local credentials = [
  kube.Secret(kube.hyphenate(s)) {
    type: 'Opaque',
    metadata+: {
      namespace: params.namespace,
    },
  } + com.makeMergeable(params.secrets[s])
  for s in std.objectFields(params.secrets)
];

{
  [if std.length(groupSyncs) > 0 then '02_groupsync']: groupSyncs,
  [if std.length(credentials) > 0 then '02_credentials']: credentials,
}
