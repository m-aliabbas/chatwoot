<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import VibeExePageShell from 'dashboard/components-next/vibeexe/VibeExePageShell.vue';
import BaseTable from 'dashboard/components-next/table/BaseTable.vue';
import BaseTableRow from 'dashboard/components-next/table/BaseTableRow.vue';
import BaseTableCell from 'dashboard/components-next/table/BaseTableCell.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import VibeExeCrmBadge from 'dashboard/components-next/vibeexe/VibeExeCrmBadge.vue';
import VibeExeCrmAPI from 'dashboard/api/vibeexeCrm';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import LeadSelector from './LeadSelector.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();
const currentUser = useMapGetter('getCurrentUser');
const currentAccountId = useMapGetter('getCurrentAccountId');

const tasks = ref([]);
const isLoading = ref(false);
const isSaving = ref(false);
const errorMessage = ref('');
const currentPage = ref(1);
const totalCount = ref(0);
const formDialog = ref(null);
const cancelDialog = ref(null);
const completeDialog = ref(null);
const rescheduleDialog = ref(null);
const editingTask = ref(null);
const cancellingTask = ref(null);
const completingTask = ref(null);
const reschedulingTask = ref(null);
const completionNote = ref('');
const rescheduleForm = ref({ due_at: '', reminder_at: '' });
const pendingFiles = ref([]);
const isUploading = ref(false);

const filters = ref({
  q: '',
  assignee_id: '',
  status: 'pending',
  task_type: '',
  priority: '',
  lead_id: '',
  created_by_id: '',
  due_from: '',
  due_to: '',
  overdue: '',
  due_today: '',
});

const emptyForm = () => ({
  lead_id: route.query.lead_id || '',
  title: '',
  description: '',
  task_type: 'follow_up',
  assignee_id: currentUser.value?.id || '',
  priority: 'medium',
  due_at: '',
  reminder_at: '',
  reminder_option: 'none',
  blob_ids: [],
});
const form = ref(emptyForm());

const agents = computed(() => store.getters['agents/getAgents'] || []);
const assigneeOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.TASKS.ALL_ASSIGNEES') },
  ...agents.value.map(agent => ({ value: agent.id, label: agent.name || agent.email })),
]);
const creatorOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.TASKS.ANY_CREATOR') },
  ...agents.value.map(agent => ({ value: agent.id, label: agent.name || agent.email })),
]);
const typeOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.TASKS.ALL_TYPES') },
  ...['follow_up', 'call', 'meeting', 'whatsapp', 'email', 'general', 'other'].map(value => ({
    value,
    label: t(`VIBEEXE_CRM.TASKS.TYPE_${value.toUpperCase()}`),
  })),
]);
const priorityOptions = computed(() => [
  { value: '', label: t('VIBEEXE_CRM.TASKS.ALL_PRIORITIES') },
  ...['low', 'medium', 'high', 'urgent'].map(value => ({ value, label: t(`VIBEEXE_CRM.WORKSPACE.PRIORITY_${value.toUpperCase()}`) })),
]);
const formTypeOptions = computed(() => typeOptions.value.filter(option => option.value));
const formPriorityOptions = computed(() => priorityOptions.value.filter(option => option.value));
const reminderOptions = computed(() => [
  { value: 'none', label: t('VIBEEXE_CRM.TASKS.REMINDER_NONE') },
  { value: 'at_due', label: t('VIBEEXE_CRM.TASKS.REMINDER_AT_DUE') },
  { value: '15_minutes', label: t('VIBEEXE_CRM.TASKS.REMINDER_15_MINUTES') },
  { value: '1_hour', label: t('VIBEEXE_CRM.TASKS.REMINDER_1_HOUR') },
  { value: '1_day', label: t('VIBEEXE_CRM.TASKS.REMINDER_1_DAY') },
  { value: 'custom', label: t('VIBEEXE_CRM.TASKS.REMINDER_CUSTOM') },
]);
const isFormValid = computed(() => form.value.lead_id && form.value.title.trim() && form.value.due_at);
const headers = computed(() => [
  t('VIBEEXE_CRM.TASKS.TASK'),
  t('VIBEEXE_CRM.TASKS.LEAD'),
  t('VIBEEXE_CRM.TASKS.TYPE'),
  t('VIBEEXE_CRM.TASKS.ASSIGNEE'),
  t('VIBEEXE_CRM.TASKS.DUE'),
  t('VIBEEXE_CRM.TASKS.STATUS'),
  t('VIBEEXE_CRM.TASKS.ACTIONS'),
]);

const cleanParams = values => Object.fromEntries(Object.entries(values).filter(([, value]) => value !== '' && value !== null));
const formatDateTime = value => value ? new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value)) : '—';

const fetchTasks = async () => {
  isLoading.value = true;
  errorMessage.value = '';
  try {
    const { data } = await VibeExeCrmAPI.getTasks({ ...cleanParams(filters.value), page: currentPage.value });
    tasks.value = data.tasks || [];
    totalCount.value = data.meta?.total_count || 0;
  } catch (error) {
    errorMessage.value = error.response?.data?.error || t('VIBEEXE_CRM.TASKS.LOAD_ERROR');
  } finally {
    isLoading.value = false;
  }
};

const showView = view => {
  filters.value.overdue = view === 'overdue' ? 'true' : '';
  filters.value.due_today = view === 'today' ? 'true' : '';
  filters.value.status = view === 'completed' ? 'completed' : view === 'all' ? '' : 'pending';
  filters.value.assignee_id = view === 'mine' ? currentUser.value?.id : '';
  currentPage.value = 1;
};

const openForm = task => {
  editingTask.value = task || null;
  pendingFiles.value = [];
  form.value = task ? {
    lead_id: task.lead.id,
    title: task.title,
    description: task.description || '',
    task_type: task.task_type,
    assignee_id: task.assignee?.id || '',
    priority: task.priority,
    due_at: task.due_at?.slice(0, 16) || '',
    reminder_at: task.reminder_at?.slice(0, 16) || '',
    reminder_option: task.reminder_at ? 'custom' : 'none',
    blob_ids: [],
  } : emptyForm();
  formDialog.value?.open();
};

const addFiles = async event => {
  const files = Array.from(event.target.files || []);
  if (!files.length) return;

  isUploading.value = true;
  try {
    for (const file of files) {
      const { fileUrl, blobId } = await uploadFile(file, currentAccountId.value);
      form.value.blob_ids.push(blobId);
      pendingFiles.value.push({ name: file.name, fileUrl, blobId });
    }
  } catch (error) {
    useAlert(error.response?.data?.error || t('VIBEEXE_CRM.TASKS.UPLOAD_ERROR'));
  } finally {
    isUploading.value = false;
    event.target.value = '';
  }
};

const removePendingFile = file => {
  form.value.blob_ids = form.value.blob_ids.filter(blobId => blobId !== file.blobId);
  pendingFiles.value = pendingFiles.value.filter(item => item.blobId !== file.blobId);
};

const removeSavedFile = async attachment => {
  await VibeExeCrmAPI.deleteTaskAttachment(editingTask.value.id, attachment.id);
  editingTask.value.attachments = editingTask.value.attachments.filter(item => item.id !== attachment.id);
};

const saveTask = async () => {
  isSaving.value = true;
  try {
    const payload = cleanParams({ ...form.value });
    delete payload.reminder_option;
    payload.reminder_at = form.value.reminder_at || null;
    if (editingTask.value) await VibeExeCrmAPI.updateTask(editingTask.value.id, payload);
    else await VibeExeCrmAPI.createTask(payload);
    formDialog.value?.close();
    useAlert(t('VIBEEXE_CRM.TASKS.SAVED'));
    await fetchTasks();
  } catch (error) {
    useAlert(error.response?.data?.error || t('VIBEEXE_CRM.TASKS.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const openCompleteDialog = task => {
  completingTask.value = task;
  completionNote.value = '';
  completeDialog.value?.open();
};

const completeTask = async () => {
  await VibeExeCrmAPI.completeTask(completingTask.value.id, completionNote.value);
  completeDialog.value?.close();
  completingTask.value = null;
  await fetchTasks();
};

const openRescheduleDialog = task => {
  reschedulingTask.value = task;
  rescheduleForm.value = {
    due_at: task.due_at?.slice(0, 16) || '',
    reminder_at: task.reminder_at?.slice(0, 16) || '',
  };
  rescheduleDialog.value?.open();
};

const rescheduleTask = async () => {
  await VibeExeCrmAPI.rescheduleTask(reschedulingTask.value.id, cleanParams(rescheduleForm.value));
  rescheduleDialog.value?.close();
  reschedulingTask.value = null;
  await fetchTasks();
};

const confirmCancel = task => {
  cancellingTask.value = task;
  cancelDialog.value?.open();
};

const cancelTask = async () => {
  await VibeExeCrmAPI.cancelTask(cancellingTask.value.id);
  cancelDialog.value?.close();
  cancellingTask.value = null;
  await fetchTasks();
};

watch(filters, () => { currentPage.value = 1; fetchTasks(); }, { deep: true });
watch(currentPage, fetchTasks);
watch(
  [() => form.value.due_at, () => form.value.reminder_option],
  ([dueAt, option]) => {
    if (option === 'custom') return;
    if (!dueAt || option === 'none') {
      form.value.reminder_at = '';
      return;
    }
    const reminder = new Date(dueAt);
    const offsets = { at_due: 0, '15_minutes': 15, '1_hour': 60, '1_day': 1440 };
    reminder.setMinutes(reminder.getMinutes() - offsets[option]);
    const timezoneOffset = reminder.getTimezoneOffset() * 60000;
    form.value.reminder_at = new Date(reminder.getTime() - timezoneOffset).toISOString().slice(0, 16);
  }
);

onMounted(async () => {
  await store.dispatch('agents/get');
  filters.value.assignee_id = currentUser.value?.id || '';
  await fetchTasks();
  if (route.query.lead_id) openForm();
});
</script>

<template>
  <VibeExePageShell :title="$t('VIBEEXE_CRM.TASKS.TITLE')" :subtitle="$t('VIBEEXE_CRM.TASKS.SUBTITLE')">
    <div class="flex flex-col gap-5">
      <header class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex flex-wrap gap-2">
          <NextButton outline slate size="sm" :label="$t('VIBEEXE_CRM.TASKS.MY_TASKS')" @click="showView('mine')" />
          <NextButton outline slate size="sm" :label="$t('VIBEEXE_CRM.TASKS.ALL_TASKS')" @click="showView('all')" />
          <NextButton outline ruby size="sm" :label="$t('VIBEEXE_CRM.TASKS.OVERDUE')" @click="showView('overdue')" />
          <NextButton outline amber size="sm" :label="$t('VIBEEXE_CRM.TASKS.DUE_TODAY')" @click="showView('today')" />
          <NextButton outline teal size="sm" :label="$t('VIBEEXE_CRM.TASKS.COMPLETED')" @click="showView('completed')" />
        </div>
        <NextButton icon="i-lucide-plus" :label="$t('VIBEEXE_CRM.TASKS.CREATE')" @click="openForm()" />
      </header>

      <section class="grid grid-cols-1 gap-3 rounded-xl border border-n-weak bg-n-surface-1 p-4 md:grid-cols-2 xl:grid-cols-5">
        <Input v-model="filters.q" size="sm" :label="$t('VIBEEXE_CRM.TASKS.SEARCH')" :placeholder="$t('VIBEEXE_CRM.TASKS.SEARCH_PLACEHOLDER')" />
        <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.TASKS.ASSIGNEE') }}<SelectInput v-model="filters.assignee_id" :options="assigneeOptions" /></label>
        <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.TASKS.TYPE') }}<SelectInput v-model="filters.task_type" :options="typeOptions" /></label>
        <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.TASKS.PRIORITY') }}<SelectInput v-model="filters.priority" :options="priorityOptions" /></label>
        <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.TASKS.STATUS') }}<SelectInput v-model="filters.status" :options="[{ value: '', label: $t('VIBEEXE_CRM.TASKS.ALL_STATUSES') }, { value: 'pending', label: $t('VIBEEXE_CRM.TASKS.PENDING') }, { value: 'completed', label: $t('VIBEEXE_CRM.TASKS.COMPLETED') }, { value: 'cancelled', label: $t('VIBEEXE_CRM.TASKS.CANCELLED') }]" /></label>
        <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11 md:col-span-2">{{ $t('VIBEEXE_CRM.TASKS.LEAD') }}<LeadSelector v-model="filters.lead_id" /></label>
        <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.TASKS.CREATED_BY') }}<SelectInput v-model="filters.created_by_id" :options="creatorOptions" /></label>
        <Input v-model="filters.due_from" type="date" :label="$t('VIBEEXE_CRM.TASKS.DUE_FROM')" />
        <Input v-model="filters.due_to" type="date" :label="$t('VIBEEXE_CRM.TASKS.DUE_TO')" />
      </section>

      <div v-if="errorMessage" role="alert" class="rounded-lg border border-n-ruby-7 bg-n-ruby-2 p-4 text-sm text-n-ruby-11">{{ errorMessage }}</div>
      <div v-if="isLoading" role="status" class="rounded-xl border border-n-weak bg-n-surface-1 p-12 text-center text-sm text-n-slate-11">{{ $t('VIBEEXE_CRM.TASKS.LOADING') }}</div>
      <p v-else-if="!tasks.length" class="rounded-xl border border-n-weak bg-n-surface-1 p-12 text-center text-sm text-n-slate-10">{{ $t('VIBEEXE_CRM.TASKS.EMPTY') }}</p>

      <div v-else class="overflow-x-auto rounded-xl border border-n-weak bg-n-surface-1">
        <BaseTable :headers="headers" :items="tasks">
          <template #row="{ items }">
            <BaseTableRow v-for="task in items" :key="task.id" :item="task" class="transition-colors hover:bg-n-surface-2">
              <BaseTableCell><p class="mb-1 font-medium text-n-slate-12">{{ task.title }}</p><div class="flex flex-wrap items-center gap-2"><VibeExeCrmBadge :value="task.priority" /><span v-if="task.attachments?.length" class="inline-flex items-center gap-1 text-xs text-n-slate-10"><i class="i-lucide-paperclip size-3" />{{ task.attachments.length }}</span></div></BaseTableCell>
              <BaseTableCell><button class="text-left text-n-blue-11 hover:underline" @click="router.push({ name: 'lead_show', params: { leadId: task.lead.id } })">{{ task.lead.title }}</button><p class="mb-0 text-xs text-n-slate-10">{{ task.lead.contact?.name }}</p></BaseTableCell>
              <BaseTableCell>{{ $t(`VIBEEXE_CRM.TASKS.TYPE_${task.task_type.toUpperCase()}`) }}</BaseTableCell>
              <BaseTableCell>{{ task.assignee?.name || $t('VIBEEXE_CRM.WORKSPACE.UNASSIGNED') }}</BaseTableCell>
              <BaseTableCell><span :class="task.overdue ? 'font-medium text-n-ruby-11' : 'text-n-slate-11'">{{ formatDateTime(task.due_at) }}</span></BaseTableCell>
              <BaseTableCell><VibeExeCrmBadge :value="task.status" /></BaseTableCell>
              <BaseTableCell><div class="flex gap-1"><NextButton v-if="task.status === 'pending'" ghost teal xs icon="i-lucide-check" :label="$t('VIBEEXE_CRM.TASKS.COMPLETE')" :disabled="!task.can_edit" @click="openCompleteDialog(task)" /><NextButton v-if="task.status === 'pending'" ghost amber xs icon="i-lucide-calendar-clock" :label="$t('VIBEEXE_CRM.TASKS.RESCHEDULE')" :disabled="!task.can_edit" @click="openRescheduleDialog(task)" /><NextButton ghost slate xs icon="i-lucide-pencil" :label="$t('VIBEEXE_CRM.TASKS.EDIT')" :disabled="!task.can_edit" @click="openForm(task)" /><NextButton v-if="task.status === 'pending'" ghost ruby xs icon="i-lucide-x" :label="$t('VIBEEXE_CRM.TASKS.CANCEL')" :disabled="!task.can_edit" @click="confirmCancel(task)" /></div></BaseTableCell>
            </BaseTableRow>
          </template>
        </BaseTable>
      </div>
      <PaginationFooter v-if="totalCount" v-model:current-page="currentPage" :total-items="totalCount" :items-per-page="25" />
    </div>

    <Dialog ref="formDialog" width="2xl" overflow-y-auto :title="editingTask ? $t('VIBEEXE_CRM.TASKS.EDIT_TASK') : $t('VIBEEXE_CRM.TASKS.CREATE_TASK')" :confirm-button-label="$t('VIBEEXE_CRM.TASKS.SAVE')" :disable-confirm-button="!isFormValid || isUploading" :is-loading="isSaving" @confirm="saveTask">
      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11 sm:col-span-2">{{ $t('VIBEEXE_CRM.TASKS.LEAD') }}<LeadSelector v-model="form.lead_id" :disabled="Boolean(editingTask)" /></label>
        <Input v-model="form.title" class="sm:col-span-2" :label="$t('VIBEEXE_CRM.TASKS.TITLE_FIELD')" />
        <TextArea
          v-model="form.description"
          class="sm:col-span-2"
          :label="$t('VIBEEXE_CRM.TASKS.DESCRIPTION')"
          :placeholder="$t('VIBEEXE_CRM.TASKS.DESCRIPTION_PLACEHOLDER')"
          :max-length="10000"
          min-height="7rem"
          max-height="16rem"
          auto-height
          resize
          show-character-count
        />
        <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.TASKS.TYPE') }}<SelectInput v-model="form.task_type" :options="formTypeOptions" /></label>
        <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.TASKS.PRIORITY') }}<SelectInput v-model="form.priority" :options="formPriorityOptions" /></label>
        <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.TASKS.ASSIGNEE') }}<SelectInput v-model="form.assignee_id" :options="assigneeOptions" /></label>
        <Input v-model="form.due_at" type="datetime-local" :label="$t('VIBEEXE_CRM.TASKS.DUE')" />
        <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.TASKS.REMINDER') }}<SelectInput v-model="form.reminder_option" :options="reminderOptions" /></label>
        <Input v-if="form.reminder_option === 'custom'" v-model="form.reminder_at" class="sm:col-span-2" type="datetime-local" :label="$t('VIBEEXE_CRM.TASKS.REMINDER_CUSTOM_TIME')" />
        <div class="sm:col-span-2">
          <label class="mb-2 block text-xs font-medium text-n-slate-11" for="task-attachments">{{ $t('VIBEEXE_CRM.TASKS.ATTACHMENTS') }}</label>
          <label for="task-attachments" class="flex min-h-24 cursor-pointer flex-col items-center justify-center gap-2 rounded-lg border border-dashed border-n-strong bg-n-surface-2 px-4 py-5 text-center hover:bg-n-surface-3 focus-within:outline focus-within:outline-2 focus-within:outline-n-blue-9">
            <i :class="isUploading ? 'i-lucide-loader-circle animate-spin' : 'i-lucide-paperclip'" class="size-5 text-n-slate-10" />
            <span class="text-sm font-medium text-n-slate-12">{{ isUploading ? $t('VIBEEXE_CRM.TASKS.UPLOADING') : $t('VIBEEXE_CRM.TASKS.ATTACH_FILES') }}</span>
            <span class="text-xs text-n-slate-10">{{ $t('VIBEEXE_CRM.TASKS.ATTACH_FILES_HELP') }}</span>
            <input id="task-attachments" class="sr-only" type="file" multiple :disabled="isUploading" @change="addFiles" />
          </label>
          <ul v-if="editingTask?.attachments?.length || pendingFiles.length" class="mt-3 space-y-2">
            <li v-for="attachment in editingTask?.attachments || []" :key="attachment.id" class="flex items-center justify-between gap-3 rounded-lg bg-n-surface-2 px-3 py-2 text-sm">
              <a :href="attachment.file_url" target="_blank" rel="noopener noreferrer" class="min-w-0 truncate text-n-blue-11 hover:underline">{{ attachment.filename }}</a>
              <NextButton ghost ruby xs icon="i-lucide-trash-2" :label="$t('VIBEEXE_CRM.TASKS.REMOVE_FILE')" @click="removeSavedFile(attachment)" />
            </li>
            <li v-for="file in pendingFiles" :key="file.blobId" class="flex items-center justify-between gap-3 rounded-lg bg-n-surface-2 px-3 py-2 text-sm">
              <a :href="file.fileUrl" target="_blank" rel="noopener noreferrer" class="min-w-0 truncate text-n-blue-11 hover:underline">{{ file.name }}</a>
              <NextButton ghost ruby xs icon="i-lucide-x" :label="$t('VIBEEXE_CRM.TASKS.REMOVE_FILE')" @click="removePendingFile(file)" />
            </li>
          </ul>
        </div>
      </div>
    </Dialog>
    <Dialog ref="completeDialog" width="lg" :title="$t('VIBEEXE_CRM.TASKS.COMPLETE_TITLE')" :description="$t('VIBEEXE_CRM.TASKS.COMPLETE_DESCRIPTION')" :confirm-button-label="$t('VIBEEXE_CRM.TASKS.COMPLETE')" @confirm="completeTask">
      <TextArea v-model="completionNote" :label="$t('VIBEEXE_CRM.TASKS.COMPLETION_NOTE')" :placeholder="$t('VIBEEXE_CRM.TASKS.COMPLETION_NOTE_PLACEHOLDER')" :max-length="5000" min-height="7rem" max-height="16rem" auto-height resize show-character-count />
    </Dialog>
    <Dialog ref="rescheduleDialog" width="lg" :title="$t('VIBEEXE_CRM.TASKS.RESCHEDULE_TITLE')" :description="$t('VIBEEXE_CRM.TASKS.RESCHEDULE_DESCRIPTION')" :confirm-button-label="$t('VIBEEXE_CRM.TASKS.RESCHEDULE')" :disable-confirm-button="!rescheduleForm.due_at" @confirm="rescheduleTask">
      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Input v-model="rescheduleForm.due_at" type="datetime-local" :label="$t('VIBEEXE_CRM.TASKS.DUE')" />
        <Input v-model="rescheduleForm.reminder_at" type="datetime-local" :label="$t('VIBEEXE_CRM.TASKS.REMINDER_CUSTOM_TIME')" />
      </div>
    </Dialog>
    <Dialog ref="cancelDialog" type="alert" width="sm" :title="$t('VIBEEXE_CRM.TASKS.CANCEL_TITLE')" :description="$t('VIBEEXE_CRM.TASKS.CANCEL_DESCRIPTION')" :confirm-button-label="$t('VIBEEXE_CRM.TASKS.CANCEL')" @confirm="cancelTask" />
  </VibeExePageShell>
</template>
