// main template for group-sync-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.group_sync_operator;

local operatorgroup = {
  apiVersion: 'operators.coreos.com/v1',
  kind: 'OperatorGroup',
  metadata: {
    name: 'group-sync-operator',
  },
  spec: {
    targetNamespaces: [
      params.namespace,
    ],
  },
};

local subscription = {
  apiVersion: 'operators.coreos.com/v1alpha1',
  kind: 'Subscription',
  metadata: {
    name: 'group-sync-operator',
  },
  spec: params.subscription,
};

local operator = [
  operatorgroup,
  subscription,
];

// Define outputs below
{
  ['01_' + std.asciiLower(obj.kind)]: obj {
    metadata+: {
      namespace: params.namespace,
    },
  }
  for obj in operator
}
