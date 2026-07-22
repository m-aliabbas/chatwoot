<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Draggable from 'vuedraggable';
import VibeExePageShell from 'dashboard/components-next/vibeexe/VibeExePageShell.vue';
import BaseTable from 'dashboard/components-next/table/BaseTable.vue';
import BaseTableRow from 'dashboard/components-next/table/BaseTableRow.vue';
import BaseTableCell from 'dashboard/components-next/table/BaseTableCell.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import VibeExeCrmBadge from 'dashboard/components-next/vibeexe/VibeExeCrmBadge.vue';
import VibeExeDetailField from 'dashboard/components-next/vibeexe/VibeExeDetailField.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import ContactSelector from 'dashboard/components-next/NewConversation/components/ContactSelector.vue';
import ContactAPI from 'dashboard/api/contacts';
import VibeExeCrmAPI from 'dashboard/api/vibeexeCrm';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import LeadTagPicker from './LeadTagPicker.vue';

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
const notes = ref([]);
const tasks = ref([]);
const boardColumns = ref([]);
const boardSnapshot = ref(null);
const isMovingBoardLead = ref(false);
const contacts = ref([]);
const selectedContact = ref(null);
const contactDropdown = ref(false);
const isLoading = ref(false);
const isSaving = ref(false);
const errorMessage = ref('');
const viewMode = ref('list');
const currentPage = ref(1);
const totalCount = ref(0);
const leadSummary = ref({ total_count: 0, stage_counts: {} });
const noteBody = ref('');
const noteFiles = ref([]);
const isUploadingNoteFile = ref(false);
const lostReason = ref('');
const formVisible = ref(false);
const editingLead = ref(null);
const formDialog = ref(null);
const lostDialog = ref(null);
const archiveDialog = ref(null);
const noteDialog = ref(null);
const deleteNoteDialog = ref(null);
const completeTaskDialog = ref(null);
const editingNote = ref(null);
const deletingNote = ref(null);
const editedNoteBody = ref('');
const taskToComplete = ref(null);
const taskCompletionNote = ref('');

const filters = ref({
  q: '',
  pipeline_id: '',
  stage_id: '',
  owner_id: '',
  team_id: '',
  priority: '',
  status: '',
  source: '',
  label_id: '',
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
const accountLabels = computed(() => store.getters['labels/getLabels'] || []);
const selectedPipeline = computed(() =>
  pipelines.value.find(pipeline => pipeline.id === Number(form.value.pipeline_id))
);
const filterPipeline = computed(() =>
  pipelines.value.find(pipeline => pipeline.id === Number(filters.value.pipeline_id))
);
const stageOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.SELECT_STAGE') },
  ...(selectedPipeline.value?.stages || []).map(stage => ({
    value: stage.id,
    label: stage.name,
  })),
]);
const allStageOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.ALL_STAGES') },
  ...pipelines.value.flatMap(pipeline =>
    pipeline.stages.map(stage => ({
      value: stage.id,
      label: `${pipeline.name} / ${stage.name}`,
    }))
  ),
]);
const pipelineOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.ALL_PIPELINES') },
  ...pipelines.value.map(pipeline => ({ value: pipeline.id, label: pipeline.name })),
]);
const ownerOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.ANY_OWNER') },
  ...agents.value.map(agent => ({ value: agent.id, label: agent.name || agent.email })),
]);
const formOwnerOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.UNASSIGNED') },
  ...agents.value.map(agent => ({ value: agent.id, label: agent.name || agent.email })),
]);
const teamOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.NO_TEAM') },
  ...teams.value.map(team => ({ value: team.id, label: team.name })),
]);
const filterTeamOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.ANY_TEAM') },
  ...teams.value.map(team => ({ value: team.id, label: team.name })),
]);
const priorityOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.ANY_PRIORITY') },
  { value: 'low', label: t('VIBEEXE_CRM.WORKSPACE.PRIORITY_LOW') },
  { value: 'medium', label: t('VIBEEXE_CRM.WORKSPACE.PRIORITY_MEDIUM') },
  { value: 'high', label: t('VIBEEXE_CRM.WORKSPACE.PRIORITY_HIGH') },
  { value: 'urgent', label: t('VIBEEXE_CRM.WORKSPACE.PRIORITY_URGENT') },
]);
const statusOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.ANY_STATUS') },
  { value: 'open', label: t('VIBEEXE_CRM.WORKSPACE.STATUS_OPEN') },
  { value: 'won', label: t('VIBEEXE_CRM.WORKSPACE.STATUS_WON') },
  { value: 'lost', label: t('VIBEEXE_CRM.WORKSPACE.STATUS_LOST') },
]);
const sourceOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.ANY_SOURCE') },
  { value: 'manual', label: t('VIBEEXE_CRM.WORKSPACE.SOURCE_MANUAL') },
  { value: 'whatsapp', label: t('VIBEEXE_CRM.WORKSPACE.SOURCE_WHATSAPP') },
  { value: 'email', label: t('VIBEEXE_CRM.WORKSPACE.SOURCE_EMAIL') },
  { value: 'web_widget', label: t('VIBEEXE_CRM.WORKSPACE.SOURCE_WEB_WIDGET') },
]);
const labelOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.WORKSPACE.ANY_TAG') },
  ...accountLabels.value.map(label => ({ value: label.id, label: label.title })),
]);
const headers = computed(() => [
  t('VIBEEXE_CRM.WORKSPACE.COL_LEAD'),
  t('VIBEEXE_CRM.WORKSPACE.COL_CONTACT'),
  t('VIBEEXE_CRM.WORKSPACE.COL_STAGE'),
  t('VIBEEXE_CRM.WORKSPACE.COL_OWNER'),
  t('VIBEEXE_CRM.WORKSPACE.COL_PRIORITY'),
  t('VIBEEXE_CRM.WORKSPACE.COL_STATUS'),
  t('VIBEEXE_CRM.WORKSPACE.COL_VALUE'),
  t('VIBEEXE_CRM.WORKSPACE.COL_ACTIVITY'),
  t('VIBEEXE_CRM.WORKSPACE.COL_CREATED'),
]);
const hasPipelines = computed(() => pipelines.value.length > 0);
const activeFilterCount = computed(() =>
  Object.entries(filters.value).filter(
    ([key, value]) =>
      value && !['sort_by', 'sort_direction', 'pipeline_id'].includes(key)
  ).length
);
const activeFilterChips = computed(() => {
  const optionSets = {
    stage_id: allStageOptions.value,
    owner_id: ownerOptions.value,
    team_id: filterTeamOptions.value,
    priority: priorityOptions.value,
    status: statusOptions.value,
    source: sourceOptions.value,
    label_id: labelOptions.value,
  };
  return Object.entries(optionSets)
    .filter(([key]) => filters.value[key])
    .map(([key, options]) => ({
      key,
      label: options.find(option => String(option.value) === String(filters.value[key]))?.label,
    }))
    .filter(chip => chip.label);
});
const isFormValid = computed(() =>
  Boolean(form.value.contact_id && form.value.title && form.value.pipeline_id && form.value.pipeline_stage_id)
);
const activeDuplicateWarnings = computed(() => {
  const warnings = selectedLead.value?.duplicate_warnings || {};
  return [
    ...(warnings.same_contact_open_leads || []),
    ...(warnings.same_pipeline_candidates || []),
    ...(warnings.matching_external_id_candidates || []),
  ].filter((lead, index, list) => list.findIndex(item => item.id === lead.id) === index);
});

const formatDate = value =>
  value
    ? new Intl.DateTimeFormat(undefined, { day: 'numeric', month: 'short', year: 'numeric' }).format(new Date(value))
    : '';
const formatDateTime = value =>
  value
    ? new Intl.DateTimeFormat(undefined, {
        day: 'numeric', month: 'short', year: 'numeric', hour: 'numeric', minute: '2-digit',
      }).format(new Date(value))
    : '';
const formatMoney = lead => {
  if (!lead.estimated_value) return '';
  return new Intl.NumberFormat(undefined, {
    style: 'currency', currency: lead.currency || 'USD', maximumFractionDigits: 2,
  }).format(lead.estimated_value);
};
const normalizedLabel = value =>
  value ? value.replaceAll('_', ' ').replace(/^./, character => character.toUpperCase()) : '';
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
    leadSummary.value = data.summary || leadSummary.value;
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
  await Promise.all([
    fetchLeadConversations(leadId),
    fetchActivities(leadId),
    fetchNotes(leadId),
    fetchTasks(leadId),
  ]);
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

const fetchNotes = async leadId => {
  const { data } = await VibeExeCrmAPI.getLeadNotes(leadId);
  notes.value = data.notes || [];
};

const fetchTasks = async leadId => {
  const { data } = await VibeExeCrmAPI.getLeadTasks(leadId);
  tasks.value = data.tasks || [];
};

const pendingTasks = computed(() =>
  tasks.value.filter(task => task.status === 'pending')
);
const completedTasks = computed(() =>
  tasks.value.filter(task => task.status === 'completed')
);
const overdueTasks = computed(() =>
  pendingTasks.value.filter(task => task.overdue)
);
const upcomingTasks = computed(() =>
  pendingTasks.value.filter(task => !task.overdue)
);

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
  formDialog.value?.open();
};

const closeForm = () => {
  formVisible.value = false;
  formDialog.value?.close();
};

const clearFilters = () => {
  const pipelineId = filters.value.pipeline_id;
  filters.value = {
    q: '', pipeline_id: pipelineId, stage_id: '', owner_id: '', team_id: '', priority: '',
    status: '', source: '', label_id: '', created_from: '', created_to: '', close_from: '', close_to: '',
    sort_by: 'last_activity_at', sort_direction: 'desc',
  };
  currentPage.value = 1;
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
    closeForm();
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

const confirmLost = async () => {
  await runLeadAction('lost');
  lostDialog.value?.close();
  lostReason.value = '';
};

const confirmArchive = async () => {
  await runLeadAction('archive');
  archiveDialog.value?.close();
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

const startBoardDrag = () => {
  boardSnapshot.value = boardColumns.value.map(column => ({
    ...column,
    leads: [...column.leads],
  }));
};

const endBoardDrag = () => {
  if (!isMovingBoardLead.value) boardSnapshot.value = null;
};

const moveBoardLead = async (event, column) => {
  if (!event.added) return;

  const lead = event.added.element;
  const previousColumns = boardSnapshot.value;
  isMovingBoardLead.value = true;

  try {
    await VibeExeCrmAPI.changeLeadStage(lead.id, {
      pipeline_stage_id: column.stage.id,
    });
    lead.pipeline_stage_id = column.stage.id;
    lead.pipeline_stage_name = column.stage.name;
  } catch (error) {
    boardColumns.value = previousColumns;
    showError(error);
  } finally {
    boardSnapshot.value = null;
    isMovingBoardLead.value = false;
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
  await VibeExeCrmAPI.addLeadNote(
    selectedLead.value.id,
    noteBody.value,
    noteFiles.value.map(file => file.blobId)
  );
  noteBody.value = '';
  noteFiles.value = [];
  await Promise.all([
    fetchNotes(selectedLead.value.id),
    fetchActivities(selectedLead.value.id),
  ]);
};

const addNoteFiles = async event => {
  const files = Array.from(event.target.files || []);
  if (!files.length) return;

  isUploadingNoteFile.value = true;
  try {
    for (const file of files) {
      const { fileUrl, blobId } = await uploadFile(file, store.getters.getCurrentAccountId);
      noteFiles.value.push({ name: file.name, fileUrl, blobId });
    }
  } catch (error) {
    showError(error);
  } finally {
    isUploadingNoteFile.value = false;
    event.target.value = '';
  }
};

const removePendingNoteFile = file => {
  noteFiles.value = noteFiles.value.filter(item => item.blobId !== file.blobId);
};

const removeNoteAttachment = async (note, attachment) => {
  await VibeExeCrmAPI.deleteLeadNoteAttachment(selectedLead.value.id, note.id, attachment.id);
  await fetchNotes(selectedLead.value.id);
};

const openNoteEditor = note => {
  editingNote.value = note;
  editedNoteBody.value = note.body;
  noteDialog.value?.open();
};

const updateNote = async () => {
  if (!editedNoteBody.value.trim()) return;
  await VibeExeCrmAPI.updateLeadNote(
    selectedLead.value.id,
    editingNote.value.id,
    editedNoteBody.value
  );
  noteDialog.value?.close();
  editingNote.value = null;
  await Promise.all([fetchNotes(selectedLead.value.id), fetchActivities(selectedLead.value.id)]);
};

const confirmDeleteNote = note => {
  deletingNote.value = note;
  deleteNoteDialog.value?.open();
};

const deleteNote = async () => {
  await VibeExeCrmAPI.deleteLeadNote(selectedLead.value.id, deletingNote.value.id);
  deleteNoteDialog.value?.close();
  deletingNote.value = null;
  await Promise.all([fetchNotes(selectedLead.value.id), fetchActivities(selectedLead.value.id)]);
};

const openTaskCompletion = task => {
  taskToComplete.value = task;
  taskCompletionNote.value = '';
  completeTaskDialog.value?.open();
};

const completeTask = async () => {
  await VibeExeCrmAPI.completeTask(taskToComplete.value.id, taskCompletionNote.value);
  completeTaskDialog.value?.close();
  taskToComplete.value = null;
  await Promise.all([
    fetchTasks(selectedLead.value.id),
    fetchActivities(selectedLead.value.id),
  ]);
};

watch(() => filters.value.pipeline_id, () => {
  filters.value.stage_id = '';
  if (viewMode.value === 'board') fetchBoard();
});
watch(() => form.value.pipeline_id, pipelineId => {
  const pipeline = pipelines.value.find(item => item.id === Number(pipelineId));
  if (!pipeline?.stages.some(stage => stage.id === Number(form.value.pipeline_stage_id))) {
    form.value.pipeline_stage_id = pipeline?.stages?.[0]?.id || '';
  }
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
  store.dispatch('labels/get');
  await fetchPipelines();
  await fetchLeads();
  if (route.params.leadId) await fetchLead(route.params.leadId);
});
</script>

<template>
  <VibeExePageShell :title="$t('VIBEEXE_CRM.WORKSPACE.TITLE')" :subtitle="$t('VIBEEXE_CRM.WORKSPACE.SUBTITLE')">
    <div class="mx-auto flex w-full max-w-[100rem] flex-col gap-5">
      <div
        v-if="!hasPipelines"
        class="flex flex-col items-start gap-3 rounded-xl border border-n-amber-7 bg-n-amber-2 p-4 text-sm text-n-slate-12 sm:flex-row sm:items-center sm:justify-between"
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
        <header class="flex flex-col gap-4 border-b border-n-weak pb-5 sm:flex-row sm:items-start sm:justify-between">
          <div class="min-w-0">
            <NextButton
              ghost
              slate
              size="sm"
              icon="i-lucide-arrow-left"
              :label="$t('VIBEEXE_CRM.WORKSPACE.BACK')"
              @click="backToList"
            />
            <div class="mt-3 flex flex-wrap items-center gap-2">
              <h2 class="mb-0 truncate text-2xl font-semibold text-n-slate-12">{{ selectedLead.title }}</h2>
              <VibeExeCrmBadge :value="selectedLead.archived_at ? 'archived' : selectedLead.status" />
            </div>
            <p class="mt-1 mb-0 text-sm text-n-slate-11">{{ selectedLead.contact?.name || $t('VIBEEXE_CRM.WORKSPACE.UNKNOWN_CONTACT') }}</p>
            <p class="mt-2 mb-0 text-xs font-medium text-n-slate-10">{{ selectedLead.pipeline_name }} <span aria-hidden="true">·</span> {{ selectedLead.pipeline_stage_name }}</p>
            <div class="mt-3"><LeadTagPicker :lead-id="selectedLead.id" /></div>
            <div class="mt-3 flex flex-wrap gap-2 text-xs">
              <span class="rounded-md bg-n-slate-3 px-2 py-1 text-n-slate-11">{{ $t('VIBEEXE_CRM.PRODUCTIVITY.OPEN_COUNT', { count: selectedLead.productivity_summary?.open_tasks_count || 0 }) }}</span>
              <span class="rounded-md bg-n-ruby-3 px-2 py-1 text-n-ruby-11">{{ $t('VIBEEXE_CRM.PRODUCTIVITY.OVERDUE_COUNT', { count: selectedLead.productivity_summary?.overdue_tasks_count || 0 }) }}</span>
              <span v-if="selectedLead.productivity_summary?.next_task_due_at" class="rounded-md bg-n-blue-3 px-2 py-1 text-n-blue-11">{{ $t('VIBEEXE_CRM.PRODUCTIVITY.NEXT_DUE', { time: formatDateTime(selectedLead.productivity_summary.next_task_due_at) }) }}</span>
            </div>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <NextButton size="sm" icon="i-lucide-pencil" :label="$t('VIBEEXE_CRM.WORKSPACE.EDIT')" @click="openForm(selectedLead)" />
            <NextButton outline teal size="sm" icon="i-lucide-trophy" :label="$t('VIBEEXE_CRM.WORKSPACE.MARK_WON')" @click="runLeadAction('won')" />
            <NextButton outline amber size="sm" icon="i-lucide-circle-x" :label="$t('VIBEEXE_CRM.WORKSPACE.MARK_LOST')" @click="lostDialog?.open()" />
            <NextButton v-if="selectedLead.archived_at" outline slate size="sm" icon="i-lucide-archive-restore" :label="$t('VIBEEXE_CRM.WORKSPACE.RESTORE')" @click="runLeadAction('restore')" />
            <NextButton v-else ghost ruby size="sm" icon="i-lucide-archive" :label="$t('VIBEEXE_CRM.WORKSPACE.ARCHIVE')" @click="archiveDialog?.open()" />
          </div>
        </header>

        <div class="grid grid-cols-1 gap-5 xl:grid-cols-[minmax(0,1fr)_21rem]">
          <main class="flex min-w-0 flex-col gap-5">
            <section class="rounded-xl border border-n-weak bg-n-surface-1 p-5">
              <h3 class="mb-4 text-base font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.OVERVIEW') }}</h3>
              <dl class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
                <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.COL_PIPELINE')" :value="selectedLead.pipeline_name" />
                <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.COL_STAGE')"><VibeExeCrmBadge :value="selectedLead.pipeline_stage_name" type="accent" /></VibeExeDetailField>
                <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.COL_VALUE')" :value="formatMoney(selectedLead)" />
                <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.COL_CLOSE')" :value="formatDate(selectedLead.expected_close_date)" />
                <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.COL_STATUS')"><VibeExeCrmBadge :value="selectedLead.status" /></VibeExeDetailField>
                <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.COL_PRIORITY')"><VibeExeCrmBadge :value="selectedLead.priority" /></VibeExeDetailField>
              </dl>
            </section>

            <section v-if="activeDuplicateWarnings.length" class="rounded-md border border-n-amber-8 bg-n-amber-2 p-4">
              <h3 class="mb-2 text-base font-medium text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.DUPLICATES') }}</h3>
              <div v-for="lead in activeDuplicateWarnings" :key="lead.id" class="flex items-center justify-between gap-3 py-2 text-sm">
                <span class="truncate text-n-slate-12">{{ lead.title }} - {{ lead.pipeline_name }}</span>
                <NextButton ghost slate xs icon="i-lucide-external-link" :label="$t('VIBEEXE_CRM.WORKSPACE.OPEN')" @click="openLead(lead)" />
              </div>
            </section>

            <section class="rounded-xl border border-n-weak bg-n-surface-1 p-5">
              <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
                <div>
                  <h3 class="mb-0 text-base font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.PRODUCTIVITY.TASKS') }}</h3>
                  <p class="mt-1 mb-0 text-xs text-n-slate-10">
                    {{ $t('VIBEEXE_CRM.PRODUCTIVITY.TASK_SUMMARY', { open: pendingTasks.length, overdue: overdueTasks.length }) }}
                  </p>
                </div>
                <NextButton size="sm" icon="i-lucide-plus" :label="$t('VIBEEXE_CRM.PRODUCTIVITY.CREATE_TASK')" @click="router.push({ name: 'tasks_index', query: { lead_id: selectedLead.id } })" />
              </div>
              <p v-if="!tasks.length" class="rounded-lg bg-n-surface-2 p-5 text-center text-sm text-n-slate-10">{{ $t('VIBEEXE_CRM.PRODUCTIVITY.NO_TASKS') }}</p>
              <h4 v-if="overdueTasks.length" class="mb-1 text-xs font-semibold uppercase tracking-wide text-n-ruby-11">{{ $t('VIBEEXE_CRM.PRODUCTIVITY.OVERDUE_TASKS') }}</h4>
              <div v-for="task in overdueTasks" :key="task.id" class="flex flex-col gap-3 border-t border-n-weak py-4 first:border-t-0 sm:flex-row sm:items-center sm:justify-between">
                <div class="min-w-0">
                  <div class="flex flex-wrap items-center gap-2">
                    <p class="mb-0 truncate font-medium text-n-slate-12">{{ task.title }}</p>
                    <VibeExeCrmBadge :value="task.priority" />
                    <span v-if="task.overdue" class="rounded-full bg-n-ruby-3 px-2 py-0.5 text-xs font-medium text-n-ruby-11">{{ $t('VIBEEXE_CRM.PRODUCTIVITY.OVERDUE') }}</span>
                    <span v-if="task.attachments?.length" class="inline-flex items-center gap-1 text-xs text-n-slate-10"><i class="i-lucide-paperclip size-3" />{{ task.attachments.length }}</span>
                  </div>
                  <p class="mt-1 mb-0 text-xs text-n-slate-10">{{ task.assignee?.name || $t('VIBEEXE_CRM.WORKSPACE.UNASSIGNED') }} · {{ formatDateTime(task.due_at) }}</p>
                </div>
                <NextButton ghost teal size="sm" icon="i-lucide-check" :label="$t('VIBEEXE_CRM.PRODUCTIVITY.COMPLETE')" :disabled="!task.can_edit" @click="openTaskCompletion(task)" />
              </div>
              <h4 v-if="upcomingTasks.length" class="mt-4 mb-1 text-xs font-semibold uppercase tracking-wide text-n-slate-10">{{ $t('VIBEEXE_CRM.PRODUCTIVITY.UPCOMING_TASKS') }}</h4>
              <div v-for="task in upcomingTasks" :key="task.id" class="flex flex-col gap-3 border-t border-n-weak py-4 first:border-t-0 sm:flex-row sm:items-center sm:justify-between">
                <div class="min-w-0"><div class="flex flex-wrap items-center gap-2"><p class="mb-0 truncate font-medium text-n-slate-12">{{ task.title }}</p><VibeExeCrmBadge :value="task.priority" /><span v-if="task.attachments?.length" class="inline-flex items-center gap-1 text-xs text-n-slate-10"><i class="i-lucide-paperclip size-3" />{{ task.attachments.length }}</span></div><p class="mt-1 mb-0 text-xs text-n-slate-10">{{ task.assignee?.name || $t('VIBEEXE_CRM.WORKSPACE.UNASSIGNED') }} · {{ formatDateTime(task.due_at) }}</p></div>
                <NextButton ghost teal size="sm" icon="i-lucide-check" :label="$t('VIBEEXE_CRM.PRODUCTIVITY.COMPLETE')" :disabled="!task.can_edit" @click="openTaskCompletion(task)" />
              </div>
              <p v-if="completedTasks.length" class="mt-3 mb-0 text-xs text-n-slate-10">{{ $t('VIBEEXE_CRM.PRODUCTIVITY.COMPLETED_COUNT', { count: completedTasks.length }) }}</p>
            </section>

            <section class="rounded-xl border border-n-weak bg-n-surface-1 p-5">
              <h3 class="mb-4 text-base font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.PRODUCTIVITY.NOTES') }}</h3>
              <div class="mb-5 flex flex-col gap-2 sm:flex-row">
                <TextArea v-model="noteBody" class="flex-1" :label="$t('VIBEEXE_CRM.PRODUCTIVITY.NOTE_LABEL')" :placeholder="$t('VIBEEXE_CRM.PRODUCTIVITY.NOTE_PLACEHOLDER')" :max-length="10000" min-height="5rem" max-height="12rem" auto-height resize show-character-count />
                <div class="flex items-end gap-2">
                  <label for="lead-note-files" class="inline-flex h-10 cursor-pointer items-center gap-2 rounded-lg border border-n-weak px-3 text-sm font-medium text-n-slate-12 hover:bg-n-surface-2 focus-within:outline focus-within:outline-2 focus-within:outline-n-blue-9">
                    <i :class="isUploadingNoteFile ? 'i-lucide-loader-circle animate-spin' : 'i-lucide-paperclip'" class="size-4" />
                    {{ $t('VIBEEXE_CRM.PRODUCTIVITY.ATTACH') }}
                    <input id="lead-note-files" class="sr-only" type="file" multiple :disabled="isUploadingNoteFile" @change="addNoteFiles" />
                  </label>
                  <NextButton icon="i-lucide-plus" :label="$t('VIBEEXE_CRM.WORKSPACE.ADD_NOTE')" :disabled="isUploadingNoteFile || !noteBody.trim()" @click="addNote" />
                </div>
              </div>
              <ul v-if="noteFiles.length" class="mb-4 flex flex-wrap gap-2">
                <li v-for="file in noteFiles" :key="file.blobId" class="inline-flex max-w-full items-center gap-2 rounded-lg bg-n-surface-2 px-3 py-2 text-xs text-n-slate-11">
                  <a :href="file.fileUrl" target="_blank" rel="noopener noreferrer" class="max-w-64 truncate text-n-blue-11 hover:underline">{{ file.name }}</a>
                  <button type="button" class="text-n-ruby-11" :aria-label="$t('VIBEEXE_CRM.PRODUCTIVITY.REMOVE_ATTACHMENT')" @click="removePendingNoteFile(file)"><i class="i-lucide-x size-3" /></button>
                </li>
              </ul>
              <p v-if="!notes.length" class="rounded-lg bg-n-surface-2 p-5 text-center text-sm text-n-slate-10">{{ $t('VIBEEXE_CRM.PRODUCTIVITY.NO_NOTES') }}</p>
              <article v-for="note in notes" :key="note.id" class="border-t border-n-weak py-4 first:border-t-0">
                <div class="mb-2 flex items-start justify-between gap-3">
                  <p class="mb-0 whitespace-pre-wrap break-words text-sm text-n-slate-12">{{ note.body }}</p>
                  <div v-if="note.can_edit || note.can_delete" class="flex shrink-0 gap-1">
                    <NextButton v-if="note.can_edit" ghost slate xs icon="i-lucide-pencil" :label="$t('VIBEEXE_CRM.PRODUCTIVITY.EDIT_NOTE')" @click="openNoteEditor(note)" />
                    <NextButton v-if="note.can_delete" ghost ruby xs icon="i-lucide-trash-2" :label="$t('VIBEEXE_CRM.PRODUCTIVITY.DELETE_NOTE')" @click="confirmDeleteNote(note)" />
                  </div>
                </div>
                <div v-if="note.attachments?.length" class="mb-2 flex flex-wrap gap-2">
                  <span v-for="attachment in note.attachments" :key="attachment.id" class="inline-flex max-w-full items-center gap-2 rounded-lg bg-n-surface-2 px-3 py-2 text-xs">
                    <i :class="attachment.content_type?.startsWith('image/') ? 'i-lucide-image' : 'i-lucide-paperclip'" class="size-3 text-n-slate-10" />
                    <a :href="attachment.file_url" target="_blank" rel="noopener noreferrer" class="max-w-64 truncate text-n-blue-11 hover:underline">{{ attachment.filename }}</a>
                    <button v-if="note.can_edit" type="button" class="text-n-ruby-11" :aria-label="$t('VIBEEXE_CRM.PRODUCTIVITY.REMOVE_ATTACHMENT')" @click="removeNoteAttachment(note, attachment)"><i class="i-lucide-trash-2 size-3" /></button>
                  </span>
                </div>
                <p class="mb-0 text-xs text-n-slate-10">{{ note.author?.name }} · {{ formatDateTime(note.created_at) }}<span v-if="note.edited_at"> · {{ $t('VIBEEXE_CRM.PRODUCTIVITY.EDITED') }}</span></p>
              </article>
            </section>

            <section class="rounded-xl border border-n-weak bg-n-surface-1 p-5">
              <div class="mb-4 flex items-center justify-between gap-3"><h3 class="mb-0 text-base font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.LINKED_CONVERSATIONS') }}</h3><span class="text-xs text-n-slate-10">{{ conversations.length }}</span></div>
              <p v-if="!conversations.length" class="rounded-lg bg-n-surface-2 p-5 text-center text-sm text-n-slate-10">{{ $t('VIBEEXE_CRM.WORKSPACE.NO_CONVERSATIONS') }}</p>
              <div v-for="conversation in conversations" :key="conversation.id" class="flex flex-col gap-3 border-t border-n-weak py-4 first:border-t-0 sm:flex-row sm:items-center sm:justify-between">
                <div class="flex min-w-0 items-start gap-3 text-sm">
                  <span class="grid size-9 shrink-0 place-items-center rounded-lg bg-n-blue-3 text-n-blue-11"><i class="i-lucide-message-square size-4" /></span>
                  <div class="min-w-0"><div class="flex flex-wrap items-center gap-2"><p class="mb-0 truncate font-medium text-n-slate-12">#{{ conversation.display_id }} · {{ conversation.inbox_name }}</p><VibeExeCrmBadge :value="conversation.status" /></div>
                  <p class="mt-1 mb-0 truncate text-n-slate-11">{{ conversation.last_message || $t('VIBEEXE_CRM.WORKSPACE.NO_PREVIEW') }}</p>
                  <p class="mt-1 mb-0 text-xs text-n-slate-10">{{ conversation.assignee_name || $t('VIBEEXE_CRM.WORKSPACE.UNASSIGNED') }}</p></div>
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

            <section class="rounded-xl border border-n-weak bg-n-surface-1 p-5">
              <h3 class="mb-4 text-base font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.ACTIVITY') }}</h3>
              <div class="relative ml-4 border-s border-n-weak pl-6">
                <div v-for="activity in activities" :key="activity.id" class="relative pb-6 text-sm last:pb-0">
                  <span class="absolute -start-[2.15rem] top-0 grid size-5 place-items-center rounded-full border border-n-weak bg-n-surface-1 text-n-slate-10"><i :class="activity.activity_type === 'note_added' ? 'i-lucide-sticky-note' : 'i-lucide-activity'" class="size-3" /></span>
                  <p class="mb-1 font-medium text-n-slate-12">{{ $t(`VIBEEXE_CRM.ACTIVITY.${activity.activity_type}`) }}</p>
                  <p class="mb-0 text-xs text-n-slate-10">{{ activity.actor?.name || $t('VIBEEXE_CRM.WORKSPACE.SYSTEM') }} · {{ formatDateTime(activity.occurred_at) }}</p>
                  <p v-if="activity.metadata?.body" class="mt-2 mb-0 rounded-lg bg-n-surface-2 p-3 text-n-slate-12">{{ activity.metadata.body }}</p>
                </div>
              </div>
            </section>
          </main>

          <aside class="h-fit rounded-xl border border-n-weak bg-n-surface-1 p-5 xl:sticky xl:top-4">
            <h3 class="mb-4 text-base font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.DETAILS') }}</h3>
            <h4 class="mb-3 text-xs font-semibold uppercase tracking-wide text-n-slate-10">{{ $t('VIBEEXE_CRM.WORKSPACE.ASSIGNMENT') }}</h4>
            <dl class="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-1">
              <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.COL_OWNER')" :value="selectedLead.owner_name || $t('VIBEEXE_CRM.WORKSPACE.UNASSIGNED')" />
              <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.COL_TEAM')" :value="selectedLead.team_name" />
            </dl>
            <h4 class="mt-5 mb-3 text-xs font-semibold uppercase tracking-wide text-n-slate-10">CRM</h4>
            <dl class="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-1">
              <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.COL_SOURCE')" :value="normalizedLabel(selectedLead.source)" />
              <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.CURRENCY')" :value="selectedLead.currency" />
              <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.CREATED')" :value="formatDateTime(selectedLead.created_at)" />
              <VibeExeDetailField :label="$t('VIBEEXE_CRM.WORKSPACE.UPDATED')" :value="formatDateTime(selectedLead.updated_at)" />
              <VibeExeDetailField v-if="selectedLead.metadata?.external_id" :label="$t('VIBEEXE_CRM.WORKSPACE.EXTERNAL_ID')" :value="selectedLead.metadata.external_id" />
            </dl>
          </aside>
        </div>
      </template>

      <template v-else>
        <header class="flex flex-col gap-4 border-b border-n-weak pb-5 lg:flex-row lg:items-center lg:justify-between">
          <div class="inline-flex w-fit rounded-lg border border-n-weak bg-n-surface-1 p-1" role="group" :aria-label="$t('VIBEEXE_CRM.WORKSPACE.VIEW')">
            <NextButton :variant="viewMode === 'list' ? 'faded' : 'ghost'" slate size="sm" icon="i-lucide-list" :label="$t('VIBEEXE_CRM.WORKSPACE.LIST')" @click="viewMode = 'list'" />
            <NextButton :variant="viewMode === 'board' ? 'faded' : 'ghost'" slate size="sm" icon="i-lucide-kanban-square" :label="$t('VIBEEXE_CRM.WORKSPACE.BOARD')" @click="viewMode = 'board'" />
          </div>
          <NextButton icon="i-lucide-plus" :label="$t('VIBEEXE_CRM.LEADS.CREATE')" :disabled="!hasPipelines" @click="openForm()" />
        </header>

        <section v-if="filterPipeline" class="flex gap-3 overflow-x-auto pb-1" :aria-label="$t('VIBEEXE_CRM.WORKSPACE.STAGE_SUMMARY')">
          <button class="min-w-36 rounded-xl border border-n-weak bg-n-surface-1 p-4 text-left transition hover:border-n-strong hover:bg-n-surface-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-blue-9" type="button" @click="filters.stage_id = ''"><span class="block truncate text-xs font-medium text-n-slate-10">{{ $t('VIBEEXE_CRM.WORKSPACE.ALL_LEADS') }}</span><strong class="mt-1 block text-2xl font-semibold text-n-slate-12">{{ leadSummary.total_count }}</strong></button>
          <button v-for="stage in filterPipeline.stages" :key="stage.id" class="min-w-36 rounded-xl border bg-n-surface-1 p-4 text-left transition hover:border-n-strong hover:bg-n-surface-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-blue-9" :class="String(filters.stage_id) === String(stage.id) ? 'border-n-blue-9 ring-1 ring-n-blue-9' : 'border-n-weak'" type="button" @click="filters.stage_id = stage.id"><span class="block truncate text-xs font-medium text-n-slate-10">{{ stage.name }}</span><strong class="mt-1 block text-2xl font-semibold text-n-slate-12">{{ leadSummary.stage_counts[stage.id] || 0 }}</strong></button>
        </section>

        <section class="rounded-xl border border-n-weak bg-n-surface-1 p-4" :aria-label="$t('VIBEEXE_CRM.WORKSPACE.FILTERS')">
          <div class="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-[minmax(14rem,1.5fr)_repeat(4,minmax(9rem,1fr))_auto]">
            <Input v-model="filters.q" size="sm" :label="$t('VIBEEXE_CRM.WORKSPACE.SEARCH_LABEL')" :placeholder="$t('VIBEEXE_CRM.WORKSPACE.SEARCH')" />
            <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_PIPELINE') }}<SelectInput v-model="filters.pipeline_id" :options="pipelineOptions" /></label>
            <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_STAGE') }}<SelectInput v-model="filters.stage_id" :options="allStageOptions" /></label>
            <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_OWNER') }}<SelectInput v-model="filters.owner_id" :options="ownerOptions" /></label>
            <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_STATUS') }}<SelectInput v-model="filters.status" :options="statusOptions" /></label>
            <Popover align="end"><NextButton outline slate size="sm" icon="i-lucide-list-filter" :label="`${$t('VIBEEXE_CRM.WORKSPACE.MORE_FILTERS')}${activeFilterCount ? ` (${activeFilterCount})` : ''}`" /><template #content><div class="grid w-[min(28rem,calc(100vw-2rem))] grid-cols-1 gap-4 p-4 sm:grid-cols-2"><label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_PRIORITY') }}<SelectInput v-model="filters.priority" :options="priorityOptions" /></label><label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_TEAM') }}<SelectInput v-model="filters.team_id" :options="filterTeamOptions" /></label><label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_SOURCE') }}<SelectInput v-model="filters.source" :options="sourceOptions" /></label><label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.TAGS') }}<SelectInput v-model="filters.label_id" :options="labelOptions" /></label><Input v-model="filters.created_from" type="date" :label="$t('VIBEEXE_CRM.WORKSPACE.CREATED_AFTER')" /><Input v-model="filters.close_from" type="date" :label="$t('VIBEEXE_CRM.WORKSPACE.CLOSES_AFTER')" /></div></template></Popover>
          </div>
          <div class="mt-3 flex flex-wrap items-center justify-between gap-3 border-t border-n-weak pt-3"><div class="flex flex-wrap items-center gap-2"><p class="mb-0 text-xs text-n-slate-10">{{ $t('VIBEEXE_CRM.WORKSPACE.RESULT_COUNT', { count: totalCount }) }}</p><button v-for="chip in activeFilterChips" :key="chip.key" class="inline-flex items-center gap-1 rounded-md bg-n-slate-3 px-2 py-1 text-xs font-medium text-n-slate-11 hover:bg-n-slate-4 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-blue-9" :aria-label="`${$t('VIBEEXE_CRM.WORKSPACE.REMOVE_FILTER')} ${chip.label}`" @click="filters[chip.key] = ''">{{ chip.label }}<i class="i-lucide-x size-3" /></button></div><NextButton v-if="activeFilterCount" ghost slate size="sm" icon="i-lucide-x" :label="$t('VIBEEXE_CRM.WORKSPACE.CLEAR_FILTERS')" @click="clearFilters" /></div>
        </section>

        <div v-if="errorMessage" role="alert" class="flex items-center gap-2 rounded-lg border border-n-ruby-7 bg-n-ruby-2 p-4 text-sm text-n-ruby-11"><i class="i-lucide-circle-alert size-4" />{{ errorMessage }}</div>
        <div v-if="isLoading" role="status" class="flex items-center justify-center gap-2 rounded-xl border border-n-weak bg-n-surface-1 p-12 text-sm text-n-slate-11"><i class="i-lucide-loader-circle size-4 animate-spin" />{{ $t('VIBEEXE_CRM.WORKSPACE.LOADING') }}</div>

        <div v-if="viewMode === 'board'" class="overflow-x-auto">
          <div class="grid min-w-[56rem] auto-cols-[18rem] grid-flow-col gap-3">
            <section v-for="column in boardColumns" :key="column.stage.id" class="rounded-xl border border-n-weak bg-n-surface-1">
              <header class="flex items-center justify-between border-b border-n-weak p-4 text-sm font-semibold text-n-slate-12"><span>{{ column.stage.name }}</span><span class="rounded-full bg-n-slate-3 px-2 py-0.5 text-xs text-n-slate-11">{{ column.leads.length }}</span></header>
              <Draggable
                v-model="column.leads"
                class="flex min-h-40 flex-col gap-2 p-3"
                :group="{ name: 'crm-leads' }"
                :disabled="isMovingBoardLead"
                item-key="id"
                handle=".lead-drag-handle"
                animation="200"
                @start="startBoardDrag"
                @end="endBoardDrag"
                @change="moveBoardLead($event, column)"
              >
                <template #item="{ element: lead }">
                  <article class="rounded-lg border border-n-weak bg-n-surface-2 p-3 text-sm transition hover:border-n-strong hover:shadow-sm">
                    <div class="mb-2 flex items-center gap-2">
                      <button class="lead-drag-handle cursor-grab text-n-slate-9 hover:text-n-slate-12 active:cursor-grabbing" type="button" :aria-label="$t('VIBEEXE_CRM.WORKSPACE.DRAG_LEAD')">
                        <i class="i-lucide-grip-vertical size-4" />
                      </button>
                      <button class="block min-w-0 flex-1 truncate text-left font-semibold text-n-slate-12 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-blue-9" @click="openLead(lead)">{{ lead.title }}</button>
                    </div>
                    <p class="mb-1 truncate text-n-slate-11">{{ lead.contact?.name || $t('VIBEEXE_CRM.WORKSPACE.UNKNOWN_CONTACT') }}</p>
                    <p class="mb-2 text-n-slate-11">{{ formatMoney(lead) }}</p>
                    <SelectInput :model-value="lead.pipeline_stage_id" :options="allStageOptions" @update:model-value="moveLeadToStage(lead, $event)" />
                  </article>
                </template>
                <template #footer>
                  <p v-if="!column.leads.length" class="pointer-events-none text-sm text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.EMPTY_STAGE') }}</p>
                </template>
              </Draggable>
            </section>
          </div>
        </div>

        <div v-else-if="!isLoading" class="overflow-x-auto rounded-xl border border-n-weak bg-n-surface-1">
          <BaseTable
            class="ltr:[&_th:first-child]:pl-4 ltr:[&_td:first-child]:pl-4 rtl:[&_th:first-child]:pr-4 rtl:[&_td:first-child]:pr-4"
            :headers="headers"
            :items="leads"
            :loading="isLoading"
            :no-data-message="$t('VIBEEXE_CRM.WORKSPACE.EMPTY_LIST')"
          >
            <template #row="{ items }">
              <BaseTableRow v-for="lead in items" :key="lead.id" :item="lead" class="transition-colors hover:bg-n-surface-2">
                <BaseTableCell><button class="max-w-56 truncate text-left font-medium text-n-blue-11 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-blue-9" :title="lead.title" @click="openLead(lead)">{{ lead.title }}</button><p class="mt-0.5 mb-0 max-w-56 truncate text-xs text-n-slate-10">{{ lead.pipeline_name }} · {{ normalizedLabel(lead.source) }}</p><div v-if="lead.tags?.length" class="mt-2 flex max-w-64 flex-wrap gap-1"><Label v-for="tag in lead.tags" :key="tag.id" :label="tag" compact /></div></BaseTableCell>
                <BaseTableCell>{{ lead.contact?.name || $t('VIBEEXE_CRM.WORKSPACE.UNKNOWN_CONTACT') }}</BaseTableCell>
                <BaseTableCell><VibeExeCrmBadge :value="lead.pipeline_stage_name" type="accent" /></BaseTableCell>
                <BaseTableCell>{{ lead.owner_name || $t('VIBEEXE_CRM.WORKSPACE.UNASSIGNED') }}</BaseTableCell>
                <BaseTableCell><VibeExeCrmBadge :value="lead.priority" /></BaseTableCell>
                <BaseTableCell><VibeExeCrmBadge :value="lead.status" /></BaseTableCell>
                <BaseTableCell><span v-if="formatMoney(lead)" class="font-medium tabular-nums text-n-slate-12">{{ formatMoney(lead) }}</span><span v-else class="text-n-slate-9">—</span></BaseTableCell>
                <BaseTableCell><span v-if="formatDateTime(lead.last_activity_at)">{{ formatDateTime(lead.last_activity_at) }}</span><span v-else class="text-n-slate-9">—</span></BaseTableCell>
                <BaseTableCell>{{ formatDate(lead.created_at) || '—' }}</BaseTableCell>
              </BaseTableRow>
            </template>
          </BaseTable>
          <PaginationFooter v-if="totalCount" v-model:current-page="currentPage" :total-items="totalCount" :items-per-page="25" />
        </div>
      </template>
    </div>

    <Dialog ref="formDialog" width="3xl" overflow-y-auto :title="editingLead ? $t('VIBEEXE_CRM.WORKSPACE.EDIT_LEAD') : $t('VIBEEXE_CRM.WORKSPACE.CREATE_LEAD')" :description="$t('VIBEEXE_CRM.WORKSPACE.FORM_DESCRIPTION')" :confirm-button-label="$t('VIBEEXE_CRM.WORKSPACE.SAVE')" :is-loading="isSaving" :disable-confirm-button="!isFormValid" @confirm="saveLead" @close="formVisible = false">
      <div v-if="formVisible" class="max-h-[65vh] space-y-6 overflow-y-auto pr-1">
        <section><h4 class="mb-3 text-sm font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.CONTACT') }}</h4><label class="mb-1 block text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.CONTACT') }}</label><div class="rounded-lg border border-n-weak">
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
          </div></section>
        <section><h4 class="mb-3 text-sm font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.LEAD_INFORMATION') }}</h4><div class="grid grid-cols-1 gap-4 sm:grid-cols-2"><Input v-model="form.title" :label="$t('VIBEEXE_CRM.WORKSPACE.COL_TITLE')" /><Input v-model="form.source" :label="$t('VIBEEXE_CRM.WORKSPACE.COL_SOURCE')" /><label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_PIPELINE') }}<SelectInput v-model="form.pipeline_id" :options="pipelineOptions.filter(option => option.value)" /></label><label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_STAGE') }}<SelectInput v-model="form.pipeline_stage_id" :options="stageOptions" /></label></div></section>
        <section><h4 class="mb-3 text-sm font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.ASSIGNMENT') }}</h4><div class="grid grid-cols-1 gap-4 sm:grid-cols-2"><label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_OWNER') }}<SelectInput v-model="form.owner_id" :options="formOwnerOptions" /></label><label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_TEAM') }}<SelectInput v-model="form.team_id" :options="teamOptions" /></label><label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.WORKSPACE.COL_PRIORITY') }}<SelectInput v-model="form.priority" :options="priorityOptions.filter(option => option.value)" /></label></div></section>
        <section><h4 class="mb-3 text-sm font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.WORKSPACE.VALUE_TIMING') }}</h4><div class="grid grid-cols-1 gap-4 sm:grid-cols-[minmax(0,1fr)_8rem]"><Input v-model="form.estimated_value" type="number" min="0" step="0.01" placeholder="250000" :label="$t('VIBEEXE_CRM.WORKSPACE.COL_VALUE')" /><Input v-model="form.currency" maxlength="3" :label="$t('VIBEEXE_CRM.WORKSPACE.CURRENCY')" /><Input v-model="form.expected_close_date" class="sm:col-span-2" type="date" :label="$t('VIBEEXE_CRM.WORKSPACE.COL_CLOSE')" /></div></section>
        <div v-if="errorMessage" role="alert" class="rounded-lg border border-n-ruby-7 bg-n-ruby-2 p-3 text-sm text-n-ruby-11">{{ errorMessage }}</div>
      </div>
    </Dialog>
    <Dialog ref="lostDialog" type="alert" width="sm" :title="$t('VIBEEXE_CRM.WORKSPACE.MARK_LOST_TITLE')" :description="$t('VIBEEXE_CRM.WORKSPACE.MARK_LOST_DESCRIPTION')" :confirm-button-label="$t('VIBEEXE_CRM.WORKSPACE.MARK_LOST')" :disable-confirm-button="!lostReason.trim()" @confirm="confirmLost"><Input v-model="lostReason" :label="$t('VIBEEXE_CRM.WORKSPACE.LOST_REASON')" /></Dialog>
    <Dialog ref="archiveDialog" type="alert" width="sm" :title="$t('VIBEEXE_CRM.WORKSPACE.ARCHIVE_TITLE')" :description="$t('VIBEEXE_CRM.WORKSPACE.ARCHIVE_DESCRIPTION')" :confirm-button-label="$t('VIBEEXE_CRM.WORKSPACE.ARCHIVE')" @confirm="confirmArchive" />
    <Dialog ref="noteDialog" width="lg" :title="$t('VIBEEXE_CRM.PRODUCTIVITY.EDIT_NOTE')" :confirm-button-label="$t('VIBEEXE_CRM.PRODUCTIVITY.SAVE_NOTE')" :disable-confirm-button="!editedNoteBody.trim()" @confirm="updateNote">
      <TextArea v-model="editedNoteBody" :label="$t('VIBEEXE_CRM.PRODUCTIVITY.NOTE_LABEL')" :max-length="10000" min-height="8rem" max-height="20rem" auto-height resize show-character-count />
    </Dialog>
    <Dialog ref="deleteNoteDialog" type="alert" width="sm" :title="$t('VIBEEXE_CRM.PRODUCTIVITY.DELETE_NOTE_TITLE')" :description="$t('VIBEEXE_CRM.PRODUCTIVITY.DELETE_NOTE_DESCRIPTION')" :confirm-button-label="$t('VIBEEXE_CRM.PRODUCTIVITY.DELETE_NOTE')" @confirm="deleteNote" />
    <Dialog ref="completeTaskDialog" width="lg" :title="$t('VIBEEXE_CRM.TASKS.COMPLETE_TITLE')" :description="$t('VIBEEXE_CRM.TASKS.COMPLETE_DESCRIPTION')" :confirm-button-label="$t('VIBEEXE_CRM.TASKS.COMPLETE')" @confirm="completeTask">
      <TextArea v-model="taskCompletionNote" :label="$t('VIBEEXE_CRM.TASKS.COMPLETION_NOTE')" :placeholder="$t('VIBEEXE_CRM.TASKS.COMPLETION_NOTE_PLACEHOLDER')" :max-length="5000" min-height="7rem" max-height="16rem" auto-height resize show-character-count />
    </Dialog>
  </VibeExePageShell>
</template>
