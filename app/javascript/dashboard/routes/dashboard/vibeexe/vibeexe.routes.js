import { frontendURL } from 'dashboard/helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import VibeExeEmptyModulePage from './VibeExeEmptyModulePage.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/leads'),
    name: 'leads_index',
    meta: {
      featureFlag: FEATURE_FLAGS.CRM,
      permissions: ['administrator', 'agent', 'contact_manage'],
      vibeexeModule: 'LEADS',
    },
    component: VibeExeEmptyModulePage,
  },
  {
    path: frontendURL('accounts/:accountId/tasks'),
    name: 'tasks_index',
    meta: {
      permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      vibeexeModule: 'TASKS',
    },
    component: VibeExeEmptyModulePage,
  },
];
