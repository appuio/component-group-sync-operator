local CommonLabels = {
  'app.kubernetes.io/managed-by': 'commodore',
  'app.kubernetes.io/part-of': 'syn',
  'app.kubernetes.io/name': 'group-sync-operator',
};

local AddCommonLabels = function(object) object {
  metadata+: {
    labels+: CommonLabels,
  },
};

{
  CommonLabels: CommonLabels,
  AddCommonLabels: AddCommonLabels,
}
