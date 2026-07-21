<script setup>
import { computed, h, onMounted, ref } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { useEventListener, useWindowSize } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { provideSidebarContext, useSidebarResize } from './provider';
import { useSidebarKeyboardShortcuts } from './useSidebarKeyboardShortcuts';
import { useVibeExeModules, VIBEEXE_MODULE_IDS } from 'dashboard/vibeexe/modules';

import Button from 'dashboard/components-next/button/Button.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';
import ChannelLeaf from './ChannelLeaf.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import Logo from 'next/icon/Logo.vue';
import SidebarAccountSwitcher from './SidebarAccountSwitcher.vue';
import SidebarGroup from './SidebarGroup.vue';
import SidebarProfileMenu from './SidebarProfileMenu.vue';

const props = defineProps({
  isMobileSidebarOpen: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'closeKeyShortcutModal',
  'openKeyShortcutModal',
  'showCreateAccountModal',
  'closeMobileSidebar',
]);

const { t } = useI18n();
const store = useStore();
const { accountScopedRoute } = useAccount();
const searchShortcut = useKbd([`$mod`, 'k']);

const isRTL = useMapGetter('accounts/isRTL');
const inboxes = useMapGetter('inboxes/getInboxes');
const labels = useMapGetter('labels/getLabelsOnSidebar');
const teams = useMapGetter('teams/getMyTeams');
const conversationCustomViews = useMapGetter(
  'customViews/getConversationCustomViews'
);
const { width: windowWidth } = useWindowSize();
const isMobile = computed(() => windowWidth.value < 768);

const {
  primaryModules,
  secondaryModules,
  bottomModules,
} = useVibeExeModules();

const expandedItem = ref(null);
const setExpandedItem = name => {
  expandedItem.value = expandedItem.value === name ? null : name;
};

const {
  sidebarWidth,
  isCollapsed,
  setSidebarWidth,
  saveWidth,
  snapToCollapsed,
  snapToExpanded,
  COLLAPSED_THRESHOLD,
} = useSidebarResize();

const isEffectivelyCollapsed = computed(
  () => !isMobile.value && isCollapsed.value
);

const isResizing = ref(false);
const startX = ref(0);
const startWidth = ref(0);

provideSidebarContext({
  expandedItem,
  setExpandedItem,
  isCollapsed: isEffectivelyCollapsed,
  sidebarWidth,
  isResizing,
});

const getClientX = event =>
  event.touches ? event.touches[0].clientX : event.clientX;

const onResizeStart = event => {
  isResizing.value = true;
  startX.value = getClientX(event);
  startWidth.value = sidebarWidth.value;
  Object.assign(document.body.style, {
    cursor: 'col-resize',
    userSelect: 'none',
  });
  event.preventDefault();
};

const onResizeMove = event => {
  if (!isResizing.value) return;

  const delta = isRTL.value
    ? startX.value - getClientX(event)
    : getClientX(event) - startX.value;
  setSidebarWidth(startWidth.value + delta);
};

const onResizeEnd = () => {
  if (!isResizing.value) return;

  isResizing.value = false;
  Object.assign(document.body.style, { cursor: '', userSelect: '' });

  if (sidebarWidth.value < COLLAPSED_THRESHOLD) {
    snapToCollapsed();
  } else {
    saveWidth();
  }
};

const onResizeHandleDoubleClick = () => {
  if (isCollapsed.value) snapToExpanded();
  else snapToCollapsed();
};

useEventListener(document, 'mousemove', onResizeMove);
useEventListener(document, 'mouseup', onResizeEnd);
useEventListener(document, 'touchmove', onResizeMove, { passive: false });
useEventListener(document, 'touchend', onResizeEnd);

const closeMobileSidebar = () => {
  if (!props.isMobileSidebarOpen) return;
  emit('closeMobileSidebar');
};

const toggleShortcutModalFn = show => {
  if (show) {
    emit('openKeyShortcutModal');
  } else {
    emit('closeKeyShortcutModal');
  }
};

useSidebarKeyboardShortcuts(toggleShortcutModalFn);

const moduleToSidebarItem = module => ({
  name: module.id,
  label: t(module.labelKey),
  icon: module.icon,
  to: module.to,
  activeOn: module.activeOn,
  getterKeys: module.countGetter ? { count: module.countGetter } : {},
});

const primaryMenuItems = computed(() =>
  primaryModules.value.map(module => {
    const item = moduleToSidebarItem(module);
    if (module.id !== VIBEEXE_MODULE_IDS.INBOX) return item;

    return {
      ...item,
      children: [
        {
          name: 'All Conversations',
          label: t('SIDEBAR.ALL_CONVERSATIONS'),
          icon: 'i-lucide-message-circle',
          to: accountScopedRoute('home'),
          activeOn: ['home', 'inbox_conversation'],
        },
        {
          name: 'Mentions',
          label: t('SIDEBAR.MENTIONED_CONVERSATIONS'),
          icon: 'i-lucide-at-sign',
          to: accountScopedRoute('conversation_mentions'),
          activeOn: ['conversation_mentions', 'conversation_through_mentions'],
        },
        {
          name: 'Participating',
          label: t('SIDEBAR.PARTICIPATING_CONVERSATIONS'),
          icon: 'i-lucide-user-round-check',
          to: accountScopedRoute('conversation_participating'),
          activeOn: [
            'conversation_participating',
            'conversation_through_participating',
          ],
        },
        {
          name: 'Unattended',
          label: t('SIDEBAR.UNATTENDED_CONVERSATIONS'),
          icon: 'i-lucide-clock-alert',
          to: accountScopedRoute('conversation_unattended'),
          activeOn: [
            'conversation_unattended',
            'conversation_through_unattended',
          ],
        },
        {
          name: 'Folders',
          label: t('SIDEBAR.CUSTOM_VIEWS_FOLDER'),
          icon: 'i-lucide-folder',
          activeOn: ['conversations_through_folders'],
          collapsible: true,
          showTreeLine: true,
          children: conversationCustomViews.value.map(view => ({
            name: `${view.name}-${view.id}`,
            label: view.name,
            to: accountScopedRoute('folder_conversations', { id: view.id }),
            activeOn: ['folder_conversations', 'conversations_through_folders'],
          })),
        },
        {
          name: 'Teams',
          label: t('SIDEBAR.TEAMS'),
          icon: 'i-lucide-users',
          activeOn: ['conversations_through_team'],
          collapsible: true,
          showTreeLine: true,
          children: teams.value.map(team => ({
            name: `${team.name}-${team.id}`,
            label: team.name,
            to: accountScopedRoute('team_conversations', { teamId: team.id }),
            activeOn: ['team_conversations', 'conversations_through_team'],
          })),
        },
        {
          name: 'Channels',
          label: t('SIDEBAR.CHANNELS'),
          icon: 'i-lucide-mailbox',
          activeOn: ['conversation_through_inbox'],
          collapsible: true,
          showTreeLine: true,
          children: inboxes.value.map(inbox => ({
            name: `${inbox.name}-${inbox.id}`,
            label: inbox.name,
            icon: h(ChannelIcon, { inbox, class: 'size-[16px]' }),
            to: accountScopedRoute('inbox_dashboard', { inbox_id: inbox.id }),
            activeOn: ['inbox_dashboard', 'conversation_through_inbox'],
            component: leafProps =>
              h(ChannelLeaf, {
                label: leafProps.label,
                active: leafProps.active,
                inbox,
                badgeCount: leafProps.badgeCount,
              }),
          })),
        },
        {
          name: 'Labels',
          label: t('SIDEBAR.LABELS'),
          icon: 'i-lucide-tag',
          activeOn: ['conversations_through_label'],
          collapsible: true,
          showTreeLine: true,
          children: labels.value.map(label => ({
            name: `${label.title}-${label.id}`,
            label: label.title,
            icon: h('span', {
              class: 'size-[8px] rounded-sm',
              style: { backgroundColor: label.color },
            }),
            to: accountScopedRoute('label_conversations', {
              label: label.title,
            }),
            activeOn: ['label_conversations', 'conversations_through_label'],
          })),
        },
      ],
    };
  })
);

const secondaryMenuItems = computed(() =>
  secondaryModules.value.map(moduleToSidebarItem)
);

const bottomMenuItems = computed(() =>
  bottomModules.value
    .filter(
      module =>
        module.id !== VIBEEXE_MODULE_IDS.PROFILE &&
        module.id !== VIBEEXE_MODULE_IDS.SETTINGS
    )
    .map(moduleToSidebarItem)
);

const settingsChildren = computed(() => [
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
]);

const settingsModule = computed(() =>
  bottomModules.value.find(module => module.id === VIBEEXE_MODULE_IDS.SETTINGS)
);

const settingsMenuItem = computed(() => {
  if (!settingsModule.value) return null;
  return {
    ...moduleToSidebarItem(settingsModule.value),
    children: settingsChildren.value,
  };
});

const visibleBottomItems = computed(() => [
  ...bottomMenuItems.value,
  ...(settingsMenuItem.value ? [settingsMenuItem.value] : []),
]);

const fetchShellData = () => {
  store.dispatch('labels/get');
  store.dispatch('inboxes/get');
  store.dispatch('notifications/unReadCount');
  store.dispatch('teams/get');
  store.dispatch('customViews/get', 'conversation');
};

onMounted(fetchShellData);
</script>

<template>
  <aside
    v-on-click-outside="[
      closeMobileSidebar,
      {
        ignore: [
          '#mobile-sidebar-launcher',
          '[data-popover-content]',
          '[data-popover-backdrop]',
        ],
      },
    ]"
    class="bg-n-background flex flex-col text-sm pb-px fixed top-0 ltr:left-0 rtl:right-0 h-full z-40 w-[200px] md:w-auto md:relative md:flex-shrink-0 md:ltr:translate-x-0 md:rtl:translate-x-0 ltr:border-r rtl:border-l border-n-weak"
    :class="[
      {
        'shadow-lg md:shadow-none': isMobileSidebarOpen,
        'ltr:-translate-x-full rtl:translate-x-full': !isMobileSidebarOpen,
        'transition-transform duration-200 ease-out md:transition-[width]':
          !isResizing,
      },
    ]"
    :style="isMobile ? undefined : { width: `${sidebarWidth}px` }"
  >
    <section
      class="grid"
      :class="isEffectivelyCollapsed ? 'mt-3 mb-6 gap-4' : 'mt-1 mb-4 gap-2'"
    >
      <div
        class="flex gap-2 items-center min-w-0"
        :class="{
          'justify-center px-1': isEffectivelyCollapsed,
          'px-2': !isEffectivelyCollapsed,
        }"
      >
        <template v-if="isEffectivelyCollapsed">
          <SidebarAccountSwitcher
            is-collapsed
            @show-create-account-modal="emit('showCreateAccountModal')"
          />
        </template>
        <template v-else>
          <div class="grid flex-shrink-0 place-content-center size-6">
            <Logo class="size-4" />
          </div>
          <div class="flex-shrink-0 w-px h-3 bg-n-strong" />
          <SidebarAccountSwitcher
            class="flex-grow -mx-1 min-w-0"
            @show-create-account-modal="emit('showCreateAccountModal')"
          />
        </template>
      </div>
      <div
        class="flex gap-2"
        :class="isEffectivelyCollapsed ? 'flex-col items-center' : 'px-2'"
      >
        <RouterLink
          v-if="!isEffectivelyCollapsed"
          :to="{ name: 'search' }"
          class="flex gap-2 items-center px-2 py-1 w-full h-7 rounded-lg outline outline-1 outline-n-weak bg-n-button-color transition-all duration-100 ease-out"
        >
          <span class="flex-shrink-0 i-lucide-search size-4 text-n-slate-10" />
          <span class="flex-grow text-start text-n-slate-10">
            {{ t('COMBOBOX.SEARCH_PLACEHOLDER') }}
          </span>
          <span
            class="hidden tracking-wide pointer-events-none select-none text-n-slate-10"
          >
            {{ searchShortcut }}
          </span>
        </RouterLink>
        <RouterLink
          v-else
          :to="{ name: 'search' }"
          class="flex items-center justify-center size-8 rounded-lg outline outline-1 outline-n-weak bg-n-button-color transition-all duration-100 ease-out hover:bg-n-alpha-2 dark:hover:bg-n-slate-9/30"
          :title="t('COMBOBOX.SEARCH_PLACEHOLDER')"
        >
          <span class="i-lucide-search size-4 text-n-slate-11" />
        </RouterLink>
        <ComposeConversation align="start">
          <template #trigger="{ isOpen }">
            <Button
              icon="i-lucide-pen-line"
              color="slate"
              size="sm"
              class="dark:hover:!bg-n-slate-9/30"
              :class="[
                isEffectivelyCollapsed
                  ? '!size-8 !outline-n-weak !text-n-slate-11'
                  : '!h-7 !outline-n-weak !text-n-slate-11',
                { '!bg-n-alpha-2 dark:!bg-n-slate-9/30': isOpen },
              ]"
            />
          </template>
        </ComposeConversation>
      </div>
    </section>

    <nav
      class="grid overflow-y-scroll flex-grow gap-4 pb-5 no-scrollbar min-w-0"
      :class="isEffectivelyCollapsed ? 'px-1' : 'px-2'"
    >
      <ul
        class="flex flex-col gap-1 m-0 list-none min-w-0"
        :class="{ 'items-center': isEffectivelyCollapsed }"
      >
        <SidebarGroup
          v-for="item in primaryMenuItems"
          :key="item.name"
          v-bind="item"
        />
      </ul>
      <ul
        v-if="secondaryMenuItems.length"
        class="flex flex-col gap-1 pt-3 m-0 list-none border-t border-n-weak min-w-0"
        :class="{ 'items-center': isEffectivelyCollapsed }"
      >
        <SidebarGroup
          v-for="item in secondaryMenuItems"
          :key="item.name"
          v-bind="item"
        />
      </ul>
    </nav>

    <section
      class="flex relative flex-col flex-shrink-0 gap-1 justify-between items-center"
    >
      <div
        class="pointer-events-none absolute inset-x-0 -top-[1.938rem] h-8 bg-gradient-to-t from-n-background to-transparent"
      />
      <div
        class="px-1 py-1.5 flex-shrink-0 grid w-full z-50 gap-1 border-t border-n-weak shadow-[0px_-2px_4px_0px_rgba(27,28,29,0.02)]"
      >
        <ul
          class="flex flex-col gap-0.5 m-0 list-none min-w-0"
          :class="{ 'items-center': isEffectivelyCollapsed }"
        >
          <SidebarGroup
            v-for="item in visibleBottomItems"
            :key="item.name"
            v-bind="item"
          />
        </ul>
        <SidebarProfileMenu
          :is-collapsed="isEffectivelyCollapsed"
          @open-key-shortcut-modal="emit('openKeyShortcutModal')"
        />
      </div>
    </section>

    <div
      class="hidden md:block absolute top-0 h-full w-1 cursor-col-resize z-40 ltr:right-0 rtl:left-0 group"
      @mousedown="onResizeStart"
      @touchstart="onResizeStart"
      @dblclick="onResizeHandleDoubleClick"
    >
      <div
        class="absolute top-0 h-full w-px ltr:right-0 rtl:left-0 bg-transparent group-hover:bg-n-brand transition-colors"
        :class="{ 'bg-n-brand': isResizing }"
      />
    </div>
  </aside>
</template>
