local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.group_sync_operator;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('group-sync-operator', params.namespace);

{
  'group-sync-operator': app,
}
