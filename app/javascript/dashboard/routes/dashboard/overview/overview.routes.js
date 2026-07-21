import { frontendURL } from 'dashboard/helper/URLHelper';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import OverviewDashboard from './OverviewDashboard.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/dashboard'),
    name: 'dashboard',
    meta: {
      permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
    },
    component: OverviewDashboard,
  },
];
