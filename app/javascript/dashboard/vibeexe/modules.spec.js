import { describe, expect, it } from 'vitest';
import { filterVibeExeModules } from './modules';

describe('filterVibeExeModules', () => {
  const modules = [
    {
      id: 'overview',
      routeName: 'dashboard',
      requiredRouteNames: ['dashboard'],
    },
    {
      id: 'reports',
      routeName: 'account_overview_reports',
      requiredRouteNames: ['account_overview_reports'],
    },
    {
      id: 'missing',
      routeName: 'missing_index',
      requiredRouteNames: ['missing_index'],
    },
  ];

  it('requires every configured route to exist', () => {
    const visibleModules = filterVibeExeModules({
      modules,
      hasRoute: routeName => routeName !== 'missing_index',
      canAccess: () => true,
    });

    expect(visibleModules.map(module => module.id)).toEqual([
      'overview',
      'reports',
    ]);
  });

  it('requires access to the module route', () => {
    const visibleModules = filterVibeExeModules({
      modules,
      hasRoute: () => true,
      canAccess: module => module.id !== 'reports',
    });

    expect(visibleModules.map(module => module.id)).toEqual([
      'overview',
      'missing',
    ]);
  });
});
