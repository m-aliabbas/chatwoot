import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export const getSettingsNavigationItems = ({ t, accountScopedRoute }) => [
  {
    name: 'Settings Account Settings',
    label: t('SIDEBAR.ACCOUNT_SETTINGS'),
    icon: 'i-lucide-briefcase',
    to: accountScopedRoute('general_settings_index'),
  },
  {
    name: 'Settings Inboxes',
    label: t('SIDEBAR.INBOXES'),
    icon: 'i-lucide-inbox',
    to: accountScopedRoute('settings_inbox_list'),
    activeOn: [
      'settings_inbox_list',
      'settings_inbox_show',
      'settings_inbox_new',
      'settings_inbox_finish',
      'settings_inboxes_page_channel',
      'settings_inboxes_add_agents',
    ],
  },
  {
    name: 'Settings CRM',
    label: t('VIBEEXE_CRM.SETTINGS.NAVIGATION'),
    icon: 'i-lucide-git-branch',
    children: [
      {
        name: 'Settings CRM Pipelines',
        label: t('VIBEEXE_CRM.SETTINGS.PIPELINES'),
        icon: 'i-lucide-git-branch',
        to: accountScopedRoute('crm_pipeline_settings'),
        activeOn: ['crm_pipeline_settings'],
        featureFlag: FEATURE_FLAGS.CRM,
        permissions: ['administrator'],
      },
    ],
  },
  {
    name: 'Settings Agents',
    label: t('SIDEBAR.AGENTS'),
    icon: 'i-lucide-square-user',
    to: accountScopedRoute('agent_list'),
  },
  {
    name: 'Settings Teams',
    label: t('SIDEBAR.TEAMS'),
    icon: 'i-lucide-users',
    to: accountScopedRoute('settings_teams_list'),
    activeOn: [
      'settings_teams_list',
      'settings_teams_new',
      'settings_teams_finish',
      'settings_teams_add_agents',
      'settings_teams_show',
      'settings_teams_edit',
      'settings_teams_edit_members',
      'settings_teams_edit_finish',
    ],
  },
  {
    name: 'Settings Labels',
    label: t('SIDEBAR.LABELS'),
    icon: 'i-lucide-tags',
    to: accountScopedRoute('labels_list'),
  },
  {
    name: 'Settings Canned Responses',
    label: t('SIDEBAR.CANNED_RESPONSES'),
    icon: 'i-lucide-message-square-quote',
    to: accountScopedRoute('canned_list'),
  },
  {
    name: 'Settings Security',
    label: t('SIDEBAR.SECURITY'),
    icon: 'i-lucide-shield',
    to: accountScopedRoute('security_settings_index'),
  },
];
