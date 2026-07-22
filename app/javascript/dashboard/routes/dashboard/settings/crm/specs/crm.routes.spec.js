import crmRoutes from '../crm.routes';

describe('CRM settings routes', () => {
  it('registers the administrator-only pipeline settings route behind CRM', () => {
    const parent = crmRoutes.routes[0];
    const pipelines = parent.children[0];

    expect(parent.path).toBe('/app/accounts/:accountId/settings/crm');
    expect(parent.meta).toMatchObject({
      permissions: ['administrator'],
      featureFlag: 'crm',
    });
    expect(pipelines).toMatchObject({
      path: 'pipelines',
      name: 'crm_pipeline_settings',
      meta: {
        permissions: ['administrator'],
        featureFlag: 'crm',
      },
    });
  });
});
