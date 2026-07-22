import { getSettingsNavigationItems } from '../settingsNavigation';

describe('settings navigation', () => {
  it('registers CRM pipelines for administrator accounts with CRM enabled', () => {
    const items = getSettingsNavigationItems({
      t: key => key,
      accountScopedRoute: name => ({ name }),
    });
    const crm = items.find(item => item.name === 'Settings CRM');
    const pipelines = crm.children[0];

    expect(crm.label).toBe('VIBEEXE_CRM.SETTINGS.NAVIGATION');
    expect(pipelines).toMatchObject({
      label: 'VIBEEXE_CRM.SETTINGS.PIPELINES',
      to: { name: 'crm_pipeline_settings' },
      activeOn: ['crm_pipeline_settings'],
      featureFlag: 'crm',
      permissions: ['administrator'],
    });
  });
});
