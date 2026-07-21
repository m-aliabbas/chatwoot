<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import VibeExePageShell from 'dashboard/components-next/vibeexe/VibeExePageShell.vue';

const { t } = useI18n();
const store = useStore();
const { accountScopedRoute, currentAccount } = useAccount();

const currentUser = useMapGetter('getCurrentUser');
const inboxes = useMapGetter('inboxes/getInboxes');
const contacts = useMapGetter('contacts/getContactsList');
const conversationStats = useMapGetter('conversationStats/getStats');

onMounted(() => {
  store.dispatch('inboxes/get');
  store.dispatch('contacts/get', { page: 1 });
  store.dispatch('conversationStats/get', { status: 'open' });
});

const welcomeName = computed(
  () => currentUser.value?.first_name || currentUser.value?.available_name || ''
);

const recentContacts = computed(() => contacts.value.slice(0, 5));

const checklistItems = computed(() => [
  {
    key: 'workspace',
    label: t('VIBEEXE_OVERVIEW.CHECKLIST.WORKSPACE_PROFILE'),
    done: Boolean(currentAccount.value?.name),
    to: accountScopedRoute('general_settings_index'),
  },
  {
    key: 'logo',
    label: t('VIBEEXE_OVERVIEW.CHECKLIST.COMPANY_LOGO'),
    done: Boolean(currentAccount.value?.settings?.logo),
    to: accountScopedRoute('general_settings_index'),
  },
  {
    key: 'channel',
    label: t('VIBEEXE_OVERVIEW.CHECKLIST.CONNECT_CHANNEL'),
    done: inboxes.value.length > 0,
    to: accountScopedRoute('settings_inbox_list'),
  },
  {
    key: 'teammate',
    label: t('VIBEEXE_OVERVIEW.CHECKLIST.INVITE_TEAMMATE'),
    done: false,
    to: accountScopedRoute('agent_list'),
  },
  {
    key: 'assignment',
    label: t('VIBEEXE_OVERVIEW.CHECKLIST.CONFIGURE_ASSIGNMENT'),
    done: inboxes.value.length > 0,
    to: accountScopedRoute('settings_inbox_list'),
  },
  {
    key: 'conversation',
    label: t('VIBEEXE_OVERVIEW.CHECKLIST.FIRST_CONVERSATION'),
    done: conversationStats.value.allCount > 0,
    to: accountScopedRoute('home'),
  },
]);

const completedChecklistCount = computed(
  () => checklistItems.value.filter(item => item.done).length
);

const summaryCards = computed(() => [
  {
    label: t('VIBEEXE_OVERVIEW.SUMMARY.OPEN'),
    value: conversationStats.value.allCount || 0,
    to: accountScopedRoute('home'),
  },
  {
    label: t('VIBEEXE_OVERVIEW.SUMMARY.UNASSIGNED'),
    value: conversationStats.value.unAssignedCount || 0,
    to: accountScopedRoute('conversation_unattended'),
  },
]);

const quickActions = computed(() => [
  {
    label: t('VIBEEXE_OVERVIEW.QUICK_ACTIONS.OPEN_INBOX'),
    icon: 'i-lucide-inbox',
    to: accountScopedRoute('home'),
  },
  {
    label: t('VIBEEXE_OVERVIEW.QUICK_ACTIONS.ADD_CONTACT'),
    icon: 'i-lucide-contact-round',
    to: accountScopedRoute('contacts_dashboard_index'),
  },
  {
    label: t('VIBEEXE_OVERVIEW.QUICK_ACTIONS.CONNECT_CHANNEL'),
    icon: 'i-lucide-plug',
    to: accountScopedRoute('settings_inbox_list'),
  },
  {
    label: t('VIBEEXE_OVERVIEW.QUICK_ACTIONS.INVITE_TEAMMATE'),
    icon: 'i-lucide-user-plus',
    to: accountScopedRoute('agent_list'),
  },
]);
</script>

<template>
  <VibeExePageShell
    :title="
      welcomeName
        ? t('VIBEEXE_OVERVIEW.TITLE_WITH_NAME', { name: welcomeName })
        : t('VIBEEXE_OVERVIEW.TITLE')
    "
    :subtitle="t('VIBEEXE_OVERVIEW.SUBTITLE')"
  >
    <div class="grid gap-4 lg:grid-cols-[minmax(0,1.5fr)_minmax(20rem,1fr)]">
      <section class="grid gap-4">
        <div class="grid gap-3 sm:grid-cols-2">
          <RouterLink
            v-for="card in summaryCards"
            :key="card.label"
            :to="card.to"
            class="rounded-lg border border-n-weak bg-n-surface-1 p-4 hover:bg-n-alpha-1"
          >
            <div class="text-sm text-n-slate-11">{{ card.label }}</div>
            <div class="mt-2 text-3xl font-semibold text-n-slate-12">
              {{ card.value }}
            </div>
          </RouterLink>
        </div>

        <section class="rounded-lg border border-n-weak bg-n-surface-1 p-4">
          <div class="flex items-center justify-between gap-3">
            <h2 class="text-base font-medium text-n-slate-12">
              {{ t('VIBEEXE_OVERVIEW.QUICK_ACTIONS.TITLE') }}
            </h2>
          </div>
          <div class="grid gap-2 mt-4 sm:grid-cols-2">
            <RouterLink
              v-for="action in quickActions"
              :key="action.label"
              :to="action.to"
              class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-1"
            >
              <span :class="[action.icon, 'size-4 text-n-slate-11']" />
              <span class="truncate">{{ action.label }}</span>
            </RouterLink>
          </div>
        </section>

        <section class="rounded-lg border border-n-weak bg-n-surface-1 p-4">
          <h2 class="text-base font-medium text-n-slate-12">
            {{ t('VIBEEXE_OVERVIEW.RECENT_CONTACTS.TITLE') }}
          </h2>
          <div v-if="recentContacts.length" class="divide-y divide-n-weak mt-3">
            <RouterLink
              v-for="contact in recentContacts"
              :key="contact.id"
              :to="accountScopedRoute('contacts_edit', { contactId: contact.id })"
              class="flex items-center justify-between gap-3 py-3 text-sm hover:bg-n-alpha-1"
            >
              <span class="min-w-0 truncate text-n-slate-12">
                {{ contact.name || contact.email || contact.phoneNumber }}
              </span>
              <span class="i-lucide-chevron-right size-4 text-n-slate-10" />
            </RouterLink>
          </div>
          <p v-else class="mt-3 text-sm text-n-slate-11">
            {{ t('VIBEEXE_OVERVIEW.RECENT_CONTACTS.EMPTY') }}
          </p>
        </section>
      </section>

      <aside class="rounded-lg border border-n-weak bg-n-surface-1 p-4">
        <div class="flex items-center justify-between gap-3">
          <h2 class="text-base font-medium text-n-slate-12">
            {{ t('VIBEEXE_OVERVIEW.CHECKLIST.TITLE') }}
          </h2>
          <span class="text-xs text-n-slate-11">
            {{
              t('VIBEEXE_OVERVIEW.CHECKLIST.PROGRESS', {
                completed: completedChecklistCount,
                total: checklistItems.length,
              })
            }}
          </span>
        </div>
        <div class="grid gap-2 mt-4">
          <RouterLink
            v-for="item in checklistItems"
            :key="item.key"
            :to="item.to"
            class="flex items-center gap-3 rounded-lg px-2 py-2 hover:bg-n-alpha-1"
          >
            <span
              class="grid place-content-center rounded-full size-5"
              :class="
                item.done
                  ? 'bg-n-teal-4 text-n-teal-11'
                  : 'bg-n-alpha-2 text-n-slate-10'
              "
            >
              <span
                :class="
                  item.done
                    ? 'i-lucide-check size-3.5'
                    : 'i-lucide-circle size-3.5'
                "
              />
            </span>
            <span class="min-w-0 text-sm text-n-slate-12">
              {{ item.label }}
            </span>
          </RouterLink>
        </div>
      </aside>
    </div>
  </VibeExePageShell>
</template>
