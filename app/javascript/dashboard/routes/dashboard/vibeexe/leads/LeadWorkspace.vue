<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import VibeExePageShell from 'dashboard/components-next/vibeexe/VibeExePageShell.vue';
import BaseTable from 'dashboard/components-next/table/BaseTable.vue';
import BaseTableRow from 'dashboard/components-next/table/BaseTableRow.vue';
import BaseTableCell from 'dashboard/components-next/table/BaseTableCell.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import ContactSelector from 'dashboard/components-next/NewConversation/components/ContactSelector.vue';
import ContactAPI from 'dashboard/api/contacts';
import VibeExeCrmAPI from 'dashboard/api/vibeexeCrm';

const router = useRouter();
const route = useRoute();
const store = useStore();
const { t } = useI18n();

const leads = ref([]);
const pipelines = ref([]);
const selectedLead = ref(null);
const conversations = ref([]);
const candidateConversations = ref([]);
const activities = ref([]);
const boardColumns = ref([]);
const contacts = ref([]);
const selectedContact = ref(null);
const contactDropdown = ref(false);
const isLoading = ref(false);
const isSaving = ref(false);
const errorMessage = ref('');
const viewMode = ref('list');
const currentPage = ref(1);
const totalCount = ref(0);
const noteBody = ref('');
const lostReason = ref('');
const formVisible = ref(false);
const editingLead = ref(null);

const filters = ref({
  q: '',
  pipeline_id: '',
  stage_id: '',
  owner_id: '',
  team_id: '',
  priority: '',
  status: '',
  source: '',
  created_from: '',
  created_to: '',
  close_from: '',
  close_to: '',
  sort_by: 'last_activity_at',
  sort_direction: 'desc',
});

const form = ref({
  contact_id: '',
  title: '',
  pipeline_id: '',
  pipeline_stage_id: '',
  owner_id: '',
  team_id: '',
  source: 'manual',
  priority: 'medium',
  estimated_value: '',
  currency: 'USD',
  expected_close_date: '',
  closed_reason: '',
});

const agents = computed(() => store.getters['agents/getAgents'] || []);
const teams = computed(() => store.getters['teams/getTeams'] || []);
const selectedPipeline = computed(() =>
  pipelines.value.find(pipeline => pipeline.id === Number(form.value.pipeline_id))
);
const stageOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.FILTER_ALL') },
  ...(selectedPipeline.value?.stages || []).map(stage => ({
    value: stage.id,
    label: stage.name,
  })),
]);
const allStageOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.FILTER_ALL') },
  ...pipelines.value.flatMap(pipeline =>
    pipeline.stages.map(stage => ({
      value: stage.id,
      label: `${pipeline.name} / ${stage.name}`,
    }))
  ),
]);
const pipelineOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.FILTER_ALL') },
  ...pipelines.value.map(pipeline => ({ value: pipeline.id, label: pipeline.name })),
]);
const ownerOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.FILTER_ALL') },
  ...agents.value.map(agent => ({ value: agent.id, label: agent.name || agent.email })),
]);
const teamOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.FILTER_ALL') },
  ...teams.value.map(team => ({ value: team.id, label: team.name })),
]);
const priorityOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.FILTER_ALL') },
  { value: 'low', label: t('VIBEEXE_CRM.WORKSPACE.PRIORITY_LOW') },
  { value: 'medium', label: t('VIBEEXE_CRM.WORKSPACE.PRIORITY_MEDIUM') },
  { value: 'high', label: t('VIBEEXE_CRM.WORKSPACE.PRIORITY_HIGH') },
  { value: 'urgent', label: t('VIBEEXE_CRM.WORKSPACE.PRIORITY_URGENT') },
]);
const statusOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.FILTER_ALL') },
  { value: 'open', label: t('VIBEEXE_CRM.WORKSPACE.STATUS_OPEN') },
  { value: 'won', label: t('VIBEEXE_CRM.WORKSPACE.STATUS_WON') },
  { value: 'lost', label: t('VIBEEXE_CRM.WORKSPACE.STATUS_LOST') },
]);
const sourceOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.FILTER_ALL') },
  { value: 'manual', label: t('VIBEEXE_CRM.WORKSPACE.SOURCE_MANUAL') },
  { value: 'whatsapp', label: t('VIBEEXE_CRM.WORKSPACE.SOURCE_WHATSAPP') },
  { value: 'email', label: t('VIBEEXE_CRM.WORKSPACE.SOURCE_EMAIL') },
  { value: 'web_widget', label: t('VIBEEXE_CRM.WORKSPACE.SOURCE_WEB_WIDGET') },
]);
const headers = computed(() => [
  t('VIBEEXE_CRM.WORKSPACE.COL_TITLE'),
  t('VIBEEXE_CRM.WORKSPACE.COL_CONTACT'),
  t('VIBEEXE_CRM.WORKSPACE.COL_PIPELINE'),
  t('VIBEEXE_CRM.WORKSPACE.COL_STAGE'),
  t('VIBEEXE_CRM.WORKSPACE.COL_OWNER'),
  t('VIBEEXE_CRM.WORKSPACE.COL_TEAM'),
  t('VIBEEXE_CRM.WORKSPACE.COL_PRIORITY'),
  t('VIBEEXE_CRM.WORKSPACE.COL_STATUS'),
  t('VIBEEXE_CRM.WORKSPACE.COL_SOURCE'),
  t('VIBEEXE_CRM.WORKSPACE.COL_VALUE'),
  t('VIBEEXE_CRM.WORKSPACE.COL_CLOSE'),
  t('VIBEEXE_CRM.WORKSPACE.COL_ACTIVITY'),
  t('VIBEEXE_CRM.WORKSPACE.COL_CREATED'),
]);
const hasPipelines = computed(() => pipelines.value.length > 0);
const activeDuplicateWarnings = computed(() => {
  const warnings = selectedLead.value?.duplicate_warnings || {};
  return [
    ...(warnings.same_contact_open_leads || []),
    ...(warnings.same_pipeline_candidates || []),
    ...(warnings.matching_external_id_candidates || []),
  ].filter((lead, index, list) => list.findIndex(item => item.id === lead.id) === index);
});

const formatDate = value => (value ? new Date(value).toLocaleDateString() : t('VIBEEXE_CRM.WORKSPACE.NOT_SET'));
const formatDateTime = value => (value ? new Date(value).toLocaleString() : t('VIBEEXE_CRM.WORKSPACE.NOT_SET'));
const formatMoney = lead => {
  if (!lead.estimated_value) return t('VIBEEXE_CRM.WORKSPACE.NOT_SET');
  return `${lead.currency || 'USD'} ${lead.estimated_value}`;
};
const showError = error => {
  errorMessage.value = error?.response?.data?.error || error?.message || t('VIBEEXE_CRM.WORKSPACE.ERROR');
  useAlert(errorMessage.value);
};
const cleanParams = params =>
  Object.fromEntries(Object.entries(params).filter(([, value]) => value !== '' && value !== null && value !== undefined));

const fetchPipelines = async () => {
  const { data } = await VibeExeCrmAPI.getPipelines();
  pipelines.value = data || [];
  if (!filters.value.pipeline_id && pipelines.value[0]) {
    filters.value.pipeline_id = pipelines.value[0].id;
  }
};

const fetchLeads = async () => {
  isLoading.value = true;
  errorMessage.value = '';
  try {
    const { data } = await VibeExeCrmAPI.getLeads(cleanParams({ ...filters.value, page: currentPage.value }));
    leads.value = data.leads || [];
    totalCount.value = data.meta?.total_count || 0;
  } catch (error) {
    showError(error);
  } finally {
    isLoading.value = false;
  }
};

const fetchBoard = async () => {
  if (!filters.value.pipeline_id) return;
  isLoading.value = true;
  try {
    const { data } = await VibeExeCrmAPI.getLeadBoard(cleanParams(filters.value));
    boardColumns.value = data.columns || [];
  } catch (error) {
    showError(error);
  } finally {
    isLoading.value = false;
  }
};

const fetchLead = async leadId => {
  const { data } = await VibeExeCrmAPI.getLead(leadId);
  selectedLead.value = data.lead;
  await Promise.all([fetchLeadConversations(leadId), fetchActivities(leadId)]);
};

const fetchLeadConversations = async leadId => {
  const { data } = await VibeExeCrmAPI.getLeadConversations(leadId);
  conversations.value = data.conversations || [];
  candidateConversations.value = data.candidates || [];
};

const fetchActivities = async leadId => {
  const { data } = await VibeExeCrmAPI.getLeadActivities(leadId);
  activities.value = data.activities || [];
};

const openLead = lead => {
  router.push({ name: 'lead_show', params: { leadId: lead.id } });
};

const backToList = () => {
  selectedLead.value = null;
  router.push({ name: 'leads_index' });
  fetchLeads();
};

const openForm = lead => {
  editingLead.value = lead || null;
  const sourceLead = lead || {};
  form.value = {
    contact_id: sourceLead.contact?.id || '',
    title: sourceLead.title || '',
    pipeline_id: sourceLead.pipeline_id || pipelines.value[0]?.id || '',
    pipeline_stage_id: sourceLead.pipeline_stage_id || pipelines.value[0]?.stages?.[0]?.id || '',
    owner_id: sourceLead.owner_id || '',
    team_id: sourceLead.team_id || '',
    source: sourceLead.source || 'manual',
    priority: sourceLead.priority || 'medium',
    estimated_value: sourceLead.estimated_value || '',
    currency: sourceLead.currency || 'USD',
    expected_close_date: sourceLead.expected_close_date || '',
    closed_reason: sourceLead.closed_reason || '',
  };
  selectedContact.value = sourceLead.contact || null;
  formVisible.value = true;
};

const searchContacts = async query => {
  if (!query) return;
  contactDropdown.value = true;
  const { data } = await ContactAPI.search(query);
  contacts.value = data.payload || data.contacts || [];
};

const setSelectedContact = contact => {
  selectedContact.value = contact;
  form.value.contact_id = contact.id;
  contactDropdown.value = false;
};

const updateContactDropdown = (_type, value) => {
  contactDropdown.value = value;
};

const clearSelectedContact = () => {
  selectedContact.value = null;
  form.value.contact_id = '';
};

const saveLead = async () => {
  isSaving.value = true;
  try {
    const payload = cleanParams(form.value);
    const { data } = editingLead.value
      ? await VibeExeCrmAPI.updateLead(editingLead.value.id, payload)
      : await VibeExeCrmAPI.createLead(payload);
    formVisible.value = false;
    useAlert(t('VIBEEXE_CRM.WORKSPACE.SAVED'));
    if (route.params.leadId || editingLead.value) {
      await fetchLead(data.lead.id);
    }
    await fetchLeads();
  } catch (error) {
    showError(error);
  } finally {
    isSaving.value = false;
  }
};

const runLeadAction = async action => {
  if (!selectedLead.value) return;
  try {
    const leadId = selectedLead.value.id;
    if (action === 'won') await VibeExeCrmAPI.markLeadWon(leadId);
    if (action === 'lost') await VibeExeCrmAPI.markLeadLost(leadId, lostReason.value);
    if (action === 'archive') await VibeExeCrmAPI.archiveLead(leadId);
    if (action === 'restore') await VibeExeCrmAPI.restoreLead(leadId);
    await fetchLead(leadId);
    await fetchLeads();
  } catch (error) {
    showError(error);
  }
};

const moveLeadToStage = async (lead, stageId) => {
  try {
    await VibeExeCrmAPI.changeLeadStage(lead.id, { pipeline_stage_id: stageId, closed_reason: lostReason.value });
    if (viewMode.value === 'board') await fetchBoard();
    if (selectedLead.value?.id === lead.id) await fetchLead(lead.id);
  } catch (error) {
    showError(error);
  }
};

const linkConversation = async conversation => {
  await VibeExeCrmAPI.linkConversationToLead(selectedLead.value.id, conversation.id);
  await fetchLeadConversations(selectedLead.value.id);
  await fetchActivities(selectedLead.value.id);
};

const unlinkConversation = async conversation => {
  await VibeExeCrmAPI.unlinkConversationFromLead(selectedLead.value.id, conversation.id);
  await fetchLeadConversations(selectedLead.value.id);
  await fetchActivities(selectedLead.value.id);
};

const addNote = async () => {
  if (!noteBody.value.trim()) return;
  await VibeExeCrmAPI.addLeadNote(selectedLead.value.id, noteBody.value);
  noteBody.value = '';
  await fetchActivities(selectedLead.value.id);
};

watch(() => filters.value.pipeline_id, () => {
  filters.value.stage_id = '';
  if (viewMode.value === 'board') fetchBoard();
});
watch([filters, currentPage], fetchLeads, { deep: true });
watch(viewMode, mode => {
  if (mode === 'board') fetchBoard();
});
watch(() => route.params.leadId, leadId => {
  if (leadId) fetchLead(leadId);
});

onMounted(async () => {
  store.dispatch('agents/get');
  store.dispatch('teams/get');
  await fetchPipelines();
  await fetchLeads();
  if (route.params.leadId) await fetchLead(route.params.leadId);
});
</script>

<template>
  <VibeExePageShell
    :title="$t('VIBEEXE_CRM.WORKSPACE.TITLE')"
    :subtitle="$t('VIBEEXE_CRM.WORKSPACE.SUBTITLE')"
  >
    <div class="flex flex-col gap-4">
      <div
        v-if="!hasPipelines"
        class="flex flex-col gap-3 rounded-md border border-n-amber-8 bg-n-amber-2 p-4 text-sm text-n-slate-12"
      >
        <p class="mb-0">
          {{ $t('VIBEEXE_CRM.WORKSPACE.NO_PIPELINES') }}
        </p>
        <NextButton
          outline
          amber
          size="sm"
          icon="i-lucide-settings"
          :label="$t('VIBEEXE_CRM.WORKSPACE.OPEN_PIPELINE_SETTINGS')"
          @click="router.push({ name: 'crm_pipeline_settings' })"
        />
      </div>

      <template v-if="selectedLead">
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div class="min-w-0">
            <NextButton
              ghost
              slate
              size="sm"
              icon="i-lucide-arrow-left"
              :label="$t('VIBEEXE_CRM.WORKSPACE.BACK')"
              @click="backToList"
            />
            <h2 class="mt-3 mb-1 text-xl font-semibold text-n-slate-12">
              {{ selectedLead.title }}
            </h2>
            <p class="mb-0 text-sm text-n-slate-11">
              {{ selectedLead.contact?.name || $t('VIBEEXE_CRM.WORKSPACE.UNKNOWN_CONTACT') }}
            </p>
          </div>
          <div class="flex flex-wrap gap-2">
            <NextButton outline slate size="sm" icon="i-lucide-pencil" :label="$t('VIBEEXE_CRM.WORKSPACE.EDIT')" @click="openForm(selectedLead)" />
            <NextButton outline teal size="sm" icon="i-lucide-trophy" :label="$t('VIBEEXE_CRM.WORKSPACE.MARK_WON')" @click="runLeadAction('won')" />
            <Input v-model="lostReason" size="sm" :placeholder="$t('VIBEEXE_CRM.WORKSPACE.LOST_REASON')" />
            <NextButton outline amber size="sm" icon="i-lucide-circle-x" :label="$t('VIBEEXE_CRM.WORKSPACE.MARK_LOST')" @click="runLeadAction('lost')" />
            <NextButton v-if="selectedLead.archived_at" outline slate size="sm" icon="i-lucide-archive-restore" :label="$t('VIBEEXE_CRM.WORKSPACE.RESTORE')" @click="runLeadAction('restore')" />
            <NextButton v-else outline ruby size="sm" icon="i-lucide-archive" :label="$t('VIBEEXE_CRM.WORKSPACE.ARCHIVE')" @click="runLeadAction('archive')" />
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 lg:grid-cols-[1fr_20rem]">
          <main class="flex flex-col gap-4">
            <section class="rounded-md border border-n-weak bg-n-surface-1 p-4">
              <h3 class="mb-3 text-base font-medium text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.OVERVIEW') }}</h3>
              <dl class="grid grid-cols-1 gap-3 sm:grid-cols-2">
                <div><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_PIPELINE') }}</dt><dd class="mb-0 text-sm text-n-slate-12">{{ selectedLead.pipeline_name }}</dd></div>
                <div><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_STAGE') }}</dt><dd class="mb-0 text-sm text-n-slate-12">{{ selectedLead.pipeline_stage_name }}</dd></div>
                <div><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_VALUE') }}</dt><dd class="mb-0 text-sm text-n-slate-12">{{ formatMoney(selectedLead) }}</dd></div>
                <div><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_CLOSE') }}</dt><dd class="mb-0 text-sm text-n-slate-12">{{ formatDate(selectedLead.expected_close_date) }}</dd></div>
              </dl>
            </section>

            <section v-if="activeDuplicateWarnings.length" class="rounded-md border border-n-amber-8 bg-n-amber-2 p-4">
              <h3 class="mb-2 text-base font-medium text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.DUPLICATES') }}</h3>
              <div v-for="lead in activeDuplicateWarnings" :key="lead.id" class="flex items-center justify-between gap-3 py-2 text-sm">
                <span class="truncate text-n-slate-12">{{ lead.title }} - {{ lead.pipeline_name }}</span>
                <NextButton ghost slate xs icon="i-lucide-external-link" :label="$t('VIBEEXE_CRM.WORKSPACE.OPEN')" @click="openLead(lead)" />
              </div>
            </section>

            <section class="rounded-md border border-n-weak bg-n-surface-1 p-4">
              <h3 class="mb-3 text-base font-medium text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.LINKED_CONVERSATIONS') }}</h3>
              <p v-if="!conversations.length" class="text-sm text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.NO_CONVERSATIONS') }}</p>
              <div v-for="conversation in conversations" :key="conversation.id" class="flex items-start justify-between gap-3 border-t border-n-weak py-3">
                <div class="min-w-0 text-sm">
                  <p class="mb-0 truncate text-n-slate-12">#{{ conversation.display_id }} - {{ conversation.inbox_name }}</p>
                  <p class="mb-0 truncate text-n-slate-11">{{ conversation.status }} - {{ conversation.assignee_name || $t('VIBEEXE_CRM.WORKSPACE.UNASSIGNED') }}</p>
                  <p class="mb-0 truncate text-n-slate-11">{{ conversation.last_message || $t('VIBEEXE_CRM.WORKSPACE.NO_PREVIEW') }}</p>
                </div>
                <div class="flex gap-1">
                  <NextButton ghost slate xs icon="i-lucide-message-square" :label="$t('VIBEEXE_CRM.WORKSPACE.OPEN')" @click="router.push({ name: 'inbox_conversation', params: { conversation_id: conversation.display_id } })" />
                  <NextButton ghost ruby xs icon="i-lucide-unlink" :label="$t('VIBEEXE_CRM.WORKSPACE.UNLINK')" @click="unlinkConversation(conversation)" />
                </div>
              </div>
              <div v-if="candidateConversations.length" class="mt-4">
                <h4 class="mb-2 text-sm font-medium text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.LINK_EXISTING') }}</h4>
                <div v-for="conversation in candidateConversations" :key="conversation.id" class="flex items-center justify-between gap-3 py-2 text-sm">
                  <span class="truncate text-n-slate-12">#{{ conversation.display_id }} - {{ conversation.inbox_name }}</span>
                  <NextButton ghost slate xs icon="i-lucide-link" :label="$t('VIBEEXE_CRM.WORKSPACE.LINK')" @click="linkConversation(conversation)" />
                </div>
              </div>
            </section>

            <section class="rounded-md border border-n-weak bg-n-surface-1 p-4">
              <h3 class="mb-3 text-base font-medium text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.ACTIVITY') }}</h3>
              <div class="mb-3 flex gap-2">
                <Input v-model="noteBody" class="flex-1" :placeholder="$t('VIBEEXE_CRM.WORKSPACE.NOTE_PLACEHOLDER')" />
                <NextButton icon="i-lucide-plus" :label="$t('VIBEEXE_CRM.WORKSPACE.ADD_NOTE')" @click="addNote" />
              </div>
              <div v-for="activity in activities" :key="activity.id" class="border-t border-n-weak py-3 text-sm">
                <p class="mb-1 text-n-slate-12">{{ $t(`VIBEEXE_CRM.ACTIVITY.${activity.activity_type}`) }}</p>
                <p class="mb-0 text-n-slate-11">{{ activity.actor?.name || $t('VIBEEXE_CRM.WORKSPACE.SYSTEM') }} - {{ formatDateTime(activity.occurred_at) }}</p>
                <p v-if="activity.metadata?.body" class="mt-1 mb-0 text-n-slate-12">{{ activity.metadata.body }}</p>
              </div>
            </section>
          </main>

          <aside class="rounded-md border border-n-weak bg-n-surface-1 p-4">
            <h3 class="mb-3 text-base font-medium text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.DETAILS') }}</h3>
            <dl class="flex flex-col gap-3 text-sm">
              <div><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_OWNER') }}</dt><dd class="mb-0 text-n-slate-12">{{ selectedLead.owner_name || $t('VIBEEXE_CRM.WORKSPACE.UNASSIGNED') }}</dd></div>
              <div><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_TEAM') }}</dt><dd class="mb-0 text-n-slate-12">{{ selectedLead.team_name || $t('VIBEEXE_CRM.WORKSPACE.NOT_SET') }}</dd></div>
              <div><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_PRIORITY') }}</dt><dd class="mb-0 text-n-slate-12">{{ selectedLead.priority }}</dd></div>
              <div><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_STATUS') }}</dt><dd class="mb-0 text-n-slate-12">{{ selectedLead.status }}</dd></div>
              <div><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_SOURCE') }}</dt><dd class="mb-0 text-n-slate-12">{{ selectedLead.source }}</dd></div>
              <div><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.CREATED') }}</dt><dd class="mb-0 text-n-slate-12">{{ formatDateTime(selectedLead.created_at) }}</dd></div>
              <div><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.UPDATED') }}</dt><dd class="mb-0 text-n-slate-12">{{ formatDateTime(selectedLead.updated_at) }}</dd></div>
              <div v-if="selectedLead.metadata?.external_id"><dt class="text-xs text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.EXTERNAL_ID') }}</dt><dd class="mb-0 text-n-slate-12">{{ selectedLead.metadata.external_id }}</dd></div>
            </dl>
          </aside>
        </div>
      </template>

      <template v-else>
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div class="flex flex-wrap gap-2">
            <Input v-model="filters.q" size="sm" :placeholder="$t('VIBEEXE_CRM.WORKSPACE.SEARCH')" />
            <SelectInput v-model="filters.pipeline_id" :options="pipelineOptions" />
            <SelectInput v-model="filters.stage_id" :options="allStageOptions" />
            <SelectInput v-model="filters.owner_id" :options="ownerOptions" />
            <SelectInput v-model="filters.team_id" :options="teamOptions" />
            <SelectInput v-model="filters.priority" :options="priorityOptions" />
            <SelectInput v-model="filters.status" :options="statusOptions" />
            <SelectInput v-model="filters.source" :options="sourceOptions" />
            <Input v-model="filters.created_from" size="sm" type="date" />
            <Input v-model="filters.close_from" size="sm" type="date" />
          </div>
          <div class="flex gap-2">
            <NextButton outline slate size="sm" icon="i-lucide-kanban-square" :label="$t('VIBEEXE_CRM.WORKSPACE.BOARD')" @click="viewMode = viewMode === 'board' ? 'list' : 'board'" />
            <NextButton icon="i-lucide-plus" :label="$t('VIBEEXE_CRM.LEADS.CREATE')" @click="openForm()" />
          </div>
        </div>

        <p v-if="errorMessage" class="text-sm text-n-ruby-11">{{ errorMessage }}</p>
        <p v-if="isLoading" class="text-sm text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.LOADING') }}</p>

        <div v-if="viewMode === 'board'" class="overflow-x-auto">
          <div class="grid min-w-[56rem] auto-cols-[18rem] grid-flow-col gap-3">
            <section v-for="column in boardColumns" :key="column.stage.id" class="rounded-md border border-n-weak bg-n-surface-1">
              <header class="border-b border-n-weak p-3 text-sm font-medium text-n-slate-12">{{ column.stage.name }}</header>
              <div class="flex min-h-40 flex-col gap-2 p-3">
                <p v-if="!column.leads.length" class="text-sm text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.EMPTY_STAGE') }}</p>
                <article v-for="lead in column.leads" :key="lead.id" class="rounded-md border border-n-weak p-3 text-sm">
                  <button class="mb-2 block max-w-full truncate text-left font-medium text-n-slate-12" @click="openLead(lead)">{{ lead.title }}</button>
                  <p class="mb-1 truncate text-n-slate-11">{{ lead.contact?.name || $t('VIBEEXE_CRM.WORKSPACE.UNKNOWN_CONTACT') }}</p>
                  <p class="mb-2 text-n-slate-11">{{ formatMoney(lead) }}</p>
                  <SelectInput :model-value="lead.pipeline_stage_id" :options="allStageOptions" @update:model-value="moveLeadToStage(lead, $event)" />
                </article>
              </div>
            </section>
          </div>
        </div>

        <div v-else class="overflow-x-auto rounded-md border border-n-weak bg-n-surface-1">
          <BaseTable :headers="headers" :items="leads" :loading="isLoading" :no-data-message="$t('VIBEEXE_CRM.WORKSPACE.EMPTY_LIST')">
            <template #row="{ items }">
              <BaseTableRow v-for="lead in items" :key="lead.id" :item="lead">
                <BaseTableCell><button class="max-w-44 truncate text-left text-n-blue-11" @click="openLead(lead)">{{ lead.title }}</button></BaseTableCell>
                <BaseTableCell>{{ lead.contact?.name || $t('VIBEEXE_CRM.WORKSPACE.UNKNOWN_CONTACT') }}</BaseTableCell>
                <BaseTableCell>{{ lead.pipeline_name }}</BaseTableCell>
                <BaseTableCell>{{ lead.pipeline_stage_name }}</BaseTableCell>
                <BaseTableCell>{{ lead.owner_name || $t('VIBEEXE_CRM.WORKSPACE.UNASSIGNED') }}</BaseTableCell>
                <BaseTableCell>{{ lead.team_name || $t('VIBEEXE_CRM.WORKSPACE.NOT_SET') }}</BaseTableCell>
                <BaseTableCell>{{ lead.priority }}</BaseTableCell>
                <BaseTableCell>{{ lead.status }}</BaseTableCell>
                <BaseTableCell>{{ lead.source }}</BaseTableCell>
                <BaseTableCell>{{ formatMoney(lead) }}</BaseTableCell>
                <BaseTableCell>{{ formatDate(lead.expected_close_date) }}</BaseTableCell>
                <BaseTableCell>{{ formatDateTime(lead.last_activity_at) }}</BaseTableCell>
                <BaseTableCell>{{ formatDate(lead.created_at) }}</BaseTableCell>
              </BaseTableRow>
            </template>
          </BaseTable>
          <PaginationFooter v-if="totalCount" v-model:current-page="currentPage" :total-items="totalCount" :items-per-page="25" />
        </div>
      </template>
    </div>

    <div v-if="formVisible" class="fixed inset-0 z-50 flex items-center justify-center bg-n-slate-12/40 p-4">
      <div class="max-h-full w-full max-w-3xl overflow-y-auto rounded-md bg-n-surface-1 p-5 shadow-xl">
        <div class="mb-4 flex items-center justify-between gap-3">
          <h3 class="mb-0 text-lg font-semibold text-n-slate-12">{{ editingLead ? $t('VIBEEXE_CRM.WORKSPACE.EDIT_LEAD') : $t('VIBEEXE_CRM.WORKSPACE.CREATE_LEAD') }}</h3>
          <NextButton ghost slate icon="i-lucide-x" @click="formVisible = false" />
        </div>
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div class="md:col-span-2 rounded-md border border-n-weak">
            <ContactSelector
              :contacts="contacts"
              :selected-contact="selectedContact"
              :show-contacts-dropdown="contactDropdown"
              :is-loading="false"
              :is-creating-contact="false"
              :show-inboxes-dropdown="false"
              :has-errors="!form.contact_id"
              @search-contacts="searchContacts"
              @set-selected-contact="setSelectedContact"
              @clear-selected-contact="clearSelectedContact"
              @update-dropdown="updateContactDropdown"
            />
          </div>
          <Input v-model="form.title" :label="$t('VIBEEXE_CRM.WORKSPACE.COL_TITLE')" />
          <Input v-model="form.source" :label="$t('VIBEEXE_CRM.WORKSPACE.COL_SOURCE')" />
          <SelectInput v-model="form.pipeline_id" :options="pipelineOptions" />
          <SelectInput v-model="form.pipeline_stage_id" :options="stageOptions" />
          <SelectInput v-model="form.owner_id" :options="ownerOptions" />
          <SelectInput v-model="form.team_id" :options="teamOptions" />
          <SelectInput v-model="form.priority" :options="priorityOptions.filter(option => option.value)" />
          <Input v-model="form.estimated_value" type="number" :label="$t('VIBEEXE_CRM.WORKSPACE.COL_VALUE')" />
          <Input v-model="form.currency" :label="$t('VIBEEXE_CRM.WORKSPACE.CURRENCY')" />
          <Input v-model="form.expected_close_date" type="date" :label="$t('VIBEEXE_CRM.WORKSPACE.COL_CLOSE')" />
          <Input v-model="form.closed_reason" :label="$t('VIBEEXE_CRM.WORKSPACE.LOST_REASON')" />
        </div>
        <div class="mt-5 flex justify-end gap-2">
          <NextButton outline slate :label="$t('VIBEEXE_CRM.WORKSPACE.CANCEL')" @click="formVisible = false" />
          <NextButton icon="i-lucide-save" :label="$t('VIBEEXE_CRM.WORKSPACE.SAVE')" :is-loading="isSaving" @click="saveLead" />
        </div>
      </div>
    </div>
  </VibeExePageShell>
</template>
