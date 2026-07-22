import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export const VIBEEXE_MODULE_IDS = {
  OVERVIEW: 'overview',
  INBOX: 'inbox',
  CONTACTS: 'contacts',
  LEADS: 'leads',
  TASKS: 'tasks',
  REPORTS: 'reports',
  AUTOMATION: 'automation',
  CAMPAIGNS: 'campaigns',
  HELP_CENTER: 'helpCenter',
  NOTIFICATIONS: 'notifications',
  PROFILE: 'profile',
  SETTINGS: 'settings',
};

export const VIBEEXE_MODULES = [
  {
    id: VIBEEXE_MODULE_IDS.OVERVIEW,
    labelKey: 'VIBEEXE_SHELL.NAV.OVERVIEW',
    icon: 'i-lucide-layout-dashboard',
    routeName: 'dashboard',
    activeOn: ['dashboard'],
    requiredRouteNames: ['dashboard'],
    enabledByDefault: true,
    section: 'primary',
  },
  {
    id: VIBEEXE_MODULE_IDS.INBOX,
    labelKey: 'VIBEEXE_SHELL.NAV.INBOX',
    icon: 'i-lucide-inbox',
    routeName: 'home',
    activeOn: [
      'home',
      'inbox_conversation',
      'inbox_dashboard',
      'conversation_through_inbox',
      'conversation_mentions',
      'conversation_through_mentions',
      'conversation_unattended',
      'conversation_through_unattended',
      'conversation_participating',
      'conversation_through_participating',
    ],
    requiredRouteNames: ['home'],
    enabledByDefault: true,
    section: 'primary',
    countGetter: 'notifications/getUnreadCount',
  },
  {
    id: VIBEEXE_MODULE_IDS.CONTACTS,
    labelKey: 'VIBEEXE_SHELL.NAV.CONTACTS',
    icon: 'i-lucide-contact',
    routeName: 'contacts_dashboard_index',
    activeOn: [
      'contacts_dashboard_index',
      'contacts_dashboard_active',
      'contacts_dashboard_segments_index',
      'contacts_dashboard_labels_index',
      'contacts_edit',
      'contacts_edit_segment',
      'contacts_edit_label',
    ],
    requiredRouteNames: ['contacts_dashboard_index'],
    featureFlag: FEATURE_FLAGS.CRM,
    section: 'primary',
  },
  {
    id: VIBEEXE_MODULE_IDS.LEADS,
    labelKey: 'VIBEEXE_SHELL.NAV.LEADS',
    icon: 'i-lucide-user-plus',
    routeName: 'leads_index',
    activeOn: ['leads_index'],
    requiredRouteNames: ['leads_index'],
    featureFlag: FEATURE_FLAGS.CRM,
    section: 'primary',
  },
  {
    id: VIBEEXE_MODULE_IDS.TASKS,
    labelKey: 'VIBEEXE_SHELL.NAV.TASKS',
    icon: 'i-lucide-list-checks',
    routeName: 'tasks_index',
    activeOn: ['tasks_index'],
    requiredRouteNames: ['tasks_index'],
    enabledByDefault: true,
    section: 'primary',
  },
  {
    id: VIBEEXE_MODULE_IDS.REPORTS,
    labelKey: 'VIBEEXE_SHELL.NAV.REPORTS',
    icon: 'i-lucide-chart-spline',
    routeName: 'account_overview_reports',
    activeOn: [
      'account_overview_reports',
      'conversation_reports',
      'agent_reports_index',
      'agent_reports_show',
      'inbox_reports_index',
      'inbox_reports_show',
      'team_reports_index',
      'team_reports_show',
      'label_reports_index',
      'label_reports_show',
      'csat_reports',
      'sla_reports',
      'bot_reports',
    ],
    requiredRouteNames: ['account_overview_reports'],
    featureFlag: FEATURE_FLAGS.REPORTS,
    section: 'primary',
  },
  {
    id: VIBEEXE_MODULE_IDS.AUTOMATION,
    labelKey: 'VIBEEXE_SHELL.NAV.AUTOMATION',
    icon: 'i-lucide-repeat',
    routeName: 'automation_list',
    activeOn: ['automation_list'],
    requiredRouteNames: ['automation_list'],
    featureFlag: FEATURE_FLAGS.AUTOMATIONS,
    section: 'secondary',
  },
  {
    id: VIBEEXE_MODULE_IDS.CAMPAIGNS,
    labelKey: 'VIBEEXE_SHELL.NAV.CAMPAIGNS',
    icon: 'i-lucide-megaphone',
    routeName: 'campaigns_livechat_index',
    activeOn: [
      'campaigns_ongoing_index',
      'campaigns_one_off_index',
      'campaigns_livechat_index',
      'campaigns_sms_index',
      'campaigns_whatsapp_index',
    ],
    requiredRouteNames: ['campaigns_livechat_index'],
    featureFlag: FEATURE_FLAGS.CAMPAIGNS,
    section: 'secondary',
  },
  {
    id: VIBEEXE_MODULE_IDS.HELP_CENTER,
    labelKey: 'VIBEEXE_SHELL.NAV.HELP_CENTER',
    icon: 'i-lucide-library-big',
    routeName: 'portals_index',
    routeParams: { navigationPath: 'portals_articles_index' },
    activeOn: [
      'portals_index',
      'portals_articles_index',
      'portals_articles_new',
      'portals_articles_edit',
      'portals_categories_index',
      'portals_categories_articles_index',
      'portals_categories_articles_edit',
      'portals_locales_index',
      'portals_settings_index',
    ],
    requiredRouteNames: ['portals_index', 'portals_articles_index'],
    featureFlag: FEATURE_FLAGS.HELP_CENTER,
    section: 'secondary',
  },
  {
    id: VIBEEXE_MODULE_IDS.NOTIFICATIONS,
    labelKey: 'VIBEEXE_SHELL.NAV.NOTIFICATIONS',
    icon: 'i-lucide-bell',
    routeName: 'notifications_index',
    activeOn: ['notifications_index'],
    requiredRouteNames: ['notifications_index'],
    enabledByDefault: true,
    section: 'bottom',
    countGetter: 'notifications/getUnreadCount',
  },
  {
    id: VIBEEXE_MODULE_IDS.PROFILE,
    labelKey: 'VIBEEXE_SHELL.NAV.PROFILE',
    icon: 'i-lucide-user-pen',
    routeName: 'profile_settings_index',
    activeOn: ['profile_settings_index'],
    requiredRouteNames: ['profile_settings_index'],
    enabledByDefault: true,
    section: 'bottom',
  },
  {
    id: VIBEEXE_MODULE_IDS.SETTINGS,
    labelKey: 'VIBEEXE_SHELL.NAV.SETTINGS',
    icon: 'i-lucide-settings',
    routeName: 'settings_home',
    activeOn: [
      'settings_home',
      'general_settings_index',
      'agent_list',
      'settings_teams_list',
      'settings_inbox_list',
      'labels_list',
      'attributes_list',
      'automation_list',
      'macros_wrapper',
      'canned_list',
      'settings_applications',
      'security_settings_index',
      'crm_pipeline_settings',
    ],
    requiredRouteNames: ['settings_home'],
    enabledByDefault: true,
    section: 'bottom',
  },
];

export const filterVibeExeModules = ({ modules, hasRoute, canAccess }) =>
  modules.filter(module => {
    const routeNames = module.requiredRouteNames || [module.routeName];
    if (!routeNames.every(routeName => hasRoute(routeName))) return false;
    return canAccess(module);
  });

export function useVibeExeModules() {
  const router = useRouter();
  const { shouldShow } = usePolicy();
  const { accountScopedRoute } = useAccount();

  const routeForModule = module =>
    accountScopedRoute(module.routeName, module.routeParams || {});

  const canAccessModule = module => {
    const route = router.resolve(routeForModule(module));
    const featureFlag = module.featureFlag || route.meta?.featureFlag || '';
    const permissions = route.meta?.permissions || [];
    const installationTypes = route.meta?.installationTypes || [];

    if (!module.enabledByDefault && !featureFlag) return false;
    return shouldShow(featureFlag, permissions, installationTypes);
  };

  const visibleModules = computed(() =>
    filterVibeExeModules({
      modules: VIBEEXE_MODULES,
      hasRoute: routeName => router.hasRoute(routeName),
      canAccess: canAccessModule,
    })
  );

  const modulesForSection = section =>
    computed(() =>
      visibleModules.value
        .filter(module => module.section === section)
        .map(module => ({
          ...module,
          to: routeForModule(module),
        }))
    );

  return {
    visibleModules,
    primaryModules: modulesForSection('primary'),
    secondaryModules: modulesForSection('secondary'),
    bottomModules: modulesForSection('bottom'),
  };
}
