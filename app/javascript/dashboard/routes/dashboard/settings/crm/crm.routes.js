import { frontendURL } from 'dashboard/helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import CrmPipelineSettings from './CrmPipelineSettings.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/crm'),
      component: SettingsWrapper,
      meta: {
        permissions: ['administrator'],
        featureFlag: FEATURE_FLAGS.CRM,
      },
      children: [
        {
          path: 'pipelines',
          name: 'crm_pipeline_settings',
          component: CrmPipelineSettings,
          meta: {
            permissions: ['administrator'],
            featureFlag: FEATURE_FLAGS.CRM,
          },
        },
      ],
    },
  ],
};
