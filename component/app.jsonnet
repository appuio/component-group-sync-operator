local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.group_sync_operator;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('group-sync-operator', params.namespace);

local appPath =
  local project = std.get(app, 'spec', { project: 'syn' }).project;
  if project == 'syn' then 'apps' else 'apps-%s' % project;

{
  ['%s/group-sync-operator' % appPath]: app,
}
