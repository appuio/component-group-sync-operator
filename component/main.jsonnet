// main template for group-sync-operator
local common = import 'common.libsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.group_sync_operator;

local prefix = 'group-sync-';

local role = std.parseJson(kap.yaml_load('group-sync-operator/manifests/controller/' + params.manifest_version + '/role.yaml'));
local service_account = std.parseJson(kap.yaml_load('group-sync-operator/manifests/controller/' + params.manifest_version + '/service_account.yaml'));
local role_binding = std.parseJson(kap.yaml_load('group-sync-operator/manifests/controller/' + params.manifest_version + '/role_binding.yaml'));
local leader_election_role = std.parseJson(kap.yaml_load('group-sync-operator/manifests/controller/' + params.manifest_version + '/leader_election_role.yaml'));
local leader_election_role_binding = std.parseJson(kap.yaml_load('group-sync-operator/manifests/controller/' + params.manifest_version + '/leader_election_role_binding.yaml'));
local deployment = std.filter(
  function(o) o.kind == 'Deployment',
  std.parseJson(kap.yaml_load_stream('group-sync-operator/manifests/controller/' + params.manifest_version + '/deployment.yaml'))
)[0];

local image = '%(registry)s/%(repository)s:%(tag)s' % params.images.operator;

local objects = [
  leader_election_role {
    metadata+: {
      name: prefix + super.name,
    },
  },
  leader_election_role_binding {
    metadata+: {
      name: prefix + super.name,
    },
    roleRef+: {
      name: prefix + super.name,
    },
    subjects: std.map(function(s) s {
      name: prefix + super.name,
      namespace: params.namespace,
    }, super.subjects),
  },
  role {
    metadata+: {
      name: prefix + super.name,
    },
  },
  role_binding {
    metadata+: {
      name: prefix + super.name,
    },
    roleRef+: {
      name: prefix + super.name,
    },
    subjects: std.map(function(s) s {
      name: prefix + super.name,
      namespace: params.namespace,
    }, super.subjects),
  },
  service_account {
    metadata+: {
      name: prefix + super.name,
    },
  },
  deployment {
    metadata+: {
      name: prefix + super.name,
    },
    spec+: {
      template+: {
        spec+: {
          serviceAccountName: prefix + super.serviceAccountName,
          containers: [
            if c.name == 'manager' then
              c {
                image: image,
                args: [],
              }
            else
              c
            for c in super.containers
          ],
        },
      },
    },
  },
];

{
  '10_namespace': kube.Namespace(params.namespace),
}
+
{
  ['20_' + std.asciiLower(obj.kind) + '_' + std.asciiLower(obj.metadata.name)]: common.AddCommonLabels(obj) {
    metadata+: {
      namespace: params.namespace,
    },
  }
  for obj in objects
}
