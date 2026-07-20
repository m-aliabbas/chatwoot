/**
 * Composable for branding-related utilities
 * Provides methods to customize text with installation-specific branding
 */
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';

const DEFAULT_INSTALLATION_NAME = 'Chatwoot';
const DEFAULT_LOGO = '/brand-assets/logo.svg';
const DEFAULT_LOGO_DARK = '/brand-assets/logo_dark.svg';
const DEFAULT_LOGO_THUMBNAIL = '/brand-assets/logo_thumbnail.svg';

const presentOrDefault = (value, fallback) => value || fallback;

const slugify = value =>
  value
    .toString()
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

export function useBranding() {
  const globalConfig = useMapGetter('globalConfig/get');

  const installationName = computed(() =>
    presentOrDefault(
      globalConfig.value?.installationName,
      DEFAULT_INSTALLATION_NAME
    )
  );

  const logo = computed(() =>
    presentOrDefault(globalConfig.value?.logo, DEFAULT_LOGO)
  );

  const logoDark = computed(() =>
    presentOrDefault(globalConfig.value?.logoDark, DEFAULT_LOGO_DARK)
  );

  const logoThumbnail = computed(() =>
    presentOrDefault(globalConfig.value?.logoThumbnail, DEFAULT_LOGO_THUMBNAIL)
  );

  const fileNamePrefix = computed(
    () => slugify(installationName.value) || slugify(DEFAULT_INSTALLATION_NAME)
  );

  /**
   * Replaces "Chatwoot" in text with the installation name from global config
   * @param {string} text - The text to process
   * @returns {string} - Text with "Chatwoot" replaced by installation name
   */
  const replaceInstallationName = text => {
    if (!text) return text;

    return text.replace(/Chatwoot/g, installationName.value);
  };

  return {
    fileNamePrefix,
    installationName,
    logo,
    logoDark,
    logoThumbnail,
    replaceInstallationName,
  };
}
