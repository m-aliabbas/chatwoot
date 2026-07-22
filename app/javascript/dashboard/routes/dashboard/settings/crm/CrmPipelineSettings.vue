<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import VibeExeCrmAPI from 'dashboard/api/vibeexeCrm';

const { t } = useI18n();
const pipelines = ref([]);
const selectedPipelineId = ref('');
const pipelineForm = ref({ name: '', active: true, default: false });
const stageForm = ref({ name: '', active: true, default: false, stage_type: 'open_stage', probability: 0 });
const isLoading = ref(false);
const isSaving = ref(false);
const isCreatingPipeline = ref(false);
const pendingDelete = ref(null);
const deleteDialog = ref(null);

const selectedPipeline = computed(() =>
  pipelines.value.find(pipeline => pipeline.id === Number(selectedPipelineId.value))
);
const selectedStages = computed(() => selectedPipeline.value?.stages || []);
const pipelineOptions = computed(() =>
  pipelines.value.map(pipeline => ({ value: pipeline.id, label: pipeline.name }))
);
const stageTypeOptions = computed(() => [
  { value: 'open_stage', label: t('VIBEEXE_CRM.SETTINGS.STAGE_OPEN') },
  { value: 'won_stage', label: t('VIBEEXE_CRM.SETTINGS.STAGE_WON') },
  { value: 'lost_stage', label: t('VIBEEXE_CRM.SETTINGS.STAGE_LOST') },
]);
const stageCountLabel = count =>
  t(
    count === 1
      ? 'VIBEEXE_CRM.SETTINGS.STAGE_COUNT_ONE'
      : 'VIBEEXE_CRM.SETTINGS.STAGE_COUNT',
    { count }
  );
const dependencySummary = (leadCount, inboxCount) => {
  const leads = t(
    leadCount === 1
      ? 'VIBEEXE_CRM.SETTINGS.LEAD_COUNT_ONE'
      : 'VIBEEXE_CRM.SETTINGS.LEAD_COUNT',
    { count: leadCount }
  );
  const inboxes = t(
    inboxCount === 1
      ? 'VIBEEXE_CRM.SETTINGS.INBOX_COUNT_ONE'
      : 'VIBEEXE_CRM.SETTINGS.INBOX_COUNT',
    { count: inboxCount }
  );
  return t('VIBEEXE_CRM.SETTINGS.DEPENDENCY_SUMMARY', { leads, inboxes });
};
const deleteDescription = computed(() => {
  if (!pendingDelete.value) return '';
  const item = pendingDelete.value.record;
  const dependencies = item.lead_count + item.inbox_default_count;
  return dependencies
    ? t('VIBEEXE_CRM.SETTINGS.DELETE_BLOCKED_DESCRIPTION', { count: dependencies })
    : t(`VIBEEXE_CRM.SETTINGS.DELETE_${pendingDelete.value.type.toUpperCase()}_DESCRIPTION`, { name: item.name });
});
const deleteBlocked = computed(() => {
  const item = pendingDelete.value?.record;
  return Boolean(item && (item.lead_count || item.inbox_default_count));
});

const showError = error =>
  useAlert(error?.response?.data?.error || error?.message || t('VIBEEXE_CRM.SETTINGS.ERROR'));

const resetPipelineForm = pipeline => {
  isCreatingPipeline.value = !pipeline;
  pipelineForm.value = pipeline
    ? { name: pipeline.name, active: pipeline.active, default: pipeline.default }
    : { name: '', active: true, default: false };
};

const selectPipeline = pipeline => {
  selectedPipelineId.value = pipeline.id;
  resetPipelineForm(pipeline);
};

const fetchPipelines = async (preferredId = selectedPipelineId.value) => {
  isLoading.value = true;
  try {
    const { data } = await VibeExeCrmAPI.getAllPipelines();
    pipelines.value = data || [];
    const pipeline = pipelines.value.find(item => item.id === Number(preferredId)) || pipelines.value[0];
    selectedPipelineId.value = pipeline?.id || '';
    resetPipelineForm(pipeline);
  } catch (error) {
    showError(error);
  } finally {
    isLoading.value = false;
  }
};

const savePipeline = async () => {
  if (!pipelineForm.value.name.trim()) return;
  isSaving.value = true;
  try {
    const response = isCreatingPipeline.value
      ? await VibeExeCrmAPI.createPipeline(pipelineForm.value)
      : await VibeExeCrmAPI.updatePipeline(selectedPipeline.value.id, pipelineForm.value);
    await fetchPipelines(response.data.pipeline.id);
    useAlert(t('VIBEEXE_CRM.SETTINGS.SAVED'));
  } catch (error) {
    showError(error);
  } finally {
    isSaving.value = false;
  }
};

const updatePipeline = async changes => {
  try {
    await VibeExeCrmAPI.updatePipeline(selectedPipeline.value.id, changes);
    await fetchPipelines(selectedPipeline.value.id);
  } catch (error) {
    showError(error);
  }
};

const bootstrapPipeline = async () => {
  isSaving.value = true;
  try {
    const { data } = await VibeExeCrmAPI.bootstrapDefaultPipeline();
    await fetchPipelines(data.pipeline.id);
    useAlert(t('VIBEEXE_CRM.SETTINGS.BOOTSTRAPPED'));
  } catch (error) {
    showError(error);
  } finally {
    isSaving.value = false;
  }
};

const saveStage = async () => {
  if (!selectedPipeline.value || !stageForm.value.name.trim()) return;
  try {
    await VibeExeCrmAPI.createStage(selectedPipeline.value.id, {
      ...stageForm.value,
      position: selectedStages.value.length,
    });
    stageForm.value = { name: '', active: true, default: false, stage_type: 'open_stage', probability: 0 };
    await fetchPipelines(selectedPipeline.value.id);
    useAlert(t('VIBEEXE_CRM.SETTINGS.SAVED'));
  } catch (error) {
    showError(error);
  }
};

const updateStage = async (stage, changes) => {
  try {
    await VibeExeCrmAPI.updateStage(selectedPipeline.value.id, stage.id, changes);
    await fetchPipelines(selectedPipeline.value.id);
  } catch (error) {
    showError(error);
  }
};

const moveStage = async (index, offset) => {
  const target = index + offset;
  if (target < 0 || target >= selectedStages.value.length) return;
  const ids = selectedStages.value.map(stage => stage.id);
  [ids[index], ids[target]] = [ids[target], ids[index]];
  try {
    await VibeExeCrmAPI.reorderStages(selectedPipeline.value.id, ids);
    await fetchPipelines(selectedPipeline.value.id);
  } catch (error) {
    showError(error);
  }
};

const requestDelete = (type, record) => {
  pendingDelete.value = { type, record };
  deleteDialog.value.open();
};

const confirmDelete = async () => {
  if (!pendingDelete.value || deleteBlocked.value) return;
  try {
    if (pendingDelete.value.type === 'pipeline') {
      await VibeExeCrmAPI.deletePipeline(pendingDelete.value.record.id);
    } else {
      await VibeExeCrmAPI.deleteStage(selectedPipeline.value.id, pendingDelete.value.record.id);
    }
    deleteDialog.value.close();
    await fetchPipelines();
  } catch (error) {
    showError(error);
  }
};

onMounted(fetchPipelines);
</script>

<template>
  <SettingsLayout :is-loading="isLoading">
    <div class="w-full" data-testid="crm-pipeline-settings">
      <BaseSettingsHeader
        :title="$t('VIBEEXE_CRM.SETTINGS.TITLE')"
        :description="$t('VIBEEXE_CRM.SETTINGS.DESCRIPTION')"
      />

      <section
        v-if="!isLoading && !pipelines.length"
        class="mt-8 flex flex-col items-center rounded-xl border border-dashed border-n-strong bg-n-surface-1 px-6 py-14 text-center"
        data-testid="crm-pipeline-empty-state"
      >
        <span class="i-lucide-git-branch mb-4 size-10 text-n-slate-9" />
        <h2 class="text-lg font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.SETTINGS.EMPTY_TITLE') }}</h2>
        <p class="mt-2 max-w-xl text-sm text-n-slate-10">{{ $t('VIBEEXE_CRM.SETTINGS.EMPTY_DESCRIPTION') }}</p>
        <NextButton
          class="mt-6"
          icon="i-lucide-sparkles"
          :is-loading="isSaving"
          :label="$t('VIBEEXE_CRM.SETTINGS.BOOTSTRAP')"
          @click="bootstrapPipeline"
        />
      </section>

      <div v-else class="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-[20rem_minmax(0,1fr)]">
        <section class="h-fit rounded-xl border border-n-weak bg-n-surface-1 p-4 lg:sticky lg:top-4">
          <div class="mb-4">
            <div>
              <h2 class="text-base font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.SETTINGS.PIPELINES') }}</h2>
              <p class="mt-1 text-sm text-n-slate-10">{{ $t('VIBEEXE_CRM.SETTINGS.PIPELINES_DESCRIPTION') }}</p>
            </div>
            <NextButton
              class="mt-4 w-full"
              sm
              icon="i-lucide-plus"
              :label="$t('VIBEEXE_CRM.SETTINGS.NEW_PIPELINE')"
              @click="resetPipelineForm()"
            />
          </div>
          <div class="flex flex-col gap-2">
            <button
              v-for="pipeline in pipelines"
              :key="pipeline.id"
              class="rounded-lg border px-3 py-3 text-left transition"
              :class="pipeline.id === Number(selectedPipelineId) ? 'border-n-blue-7 bg-n-blue-3' : 'border-n-weak hover:bg-n-surface-2'"
              @click="selectPipeline(pipeline)"
            >
              <span class="flex items-center justify-between gap-2">
                <span class="truncate text-sm font-medium text-n-slate-12">{{ pipeline.name }}</span>
                <span v-if="pipeline.default" class="rounded bg-n-blue-4 px-2 py-0.5 text-xs text-n-blue-11">{{ $t('VIBEEXE_CRM.SETTINGS.DEFAULT') }}</span>
              </span>
              <span class="mt-1 block text-xs text-n-slate-10">
                {{ stageCountLabel(pipeline.stages.length) }} ·
                {{ pipeline.active ? $t('VIBEEXE_CRM.SETTINGS.ACTIVE') : $t('VIBEEXE_CRM.SETTINGS.INACTIVE') }}
              </span>
            </button>
          </div>
        </section>

        <main class="flex min-w-0 flex-col gap-6">
          <section class="rounded-xl border border-n-weak bg-n-surface-1 p-5">
            <div class="mb-4 flex items-center justify-between gap-3">
              <div>
                <h2 class="text-base font-semibold text-n-slate-12">{{ isCreatingPipeline ? $t('VIBEEXE_CRM.SETTINGS.NEW_PIPELINE') : $t('VIBEEXE_CRM.SETTINGS.PIPELINE_DETAILS') }}</h2>
                <p class="mt-1 text-sm text-n-slate-10">{{ $t('VIBEEXE_CRM.SETTINGS.PIPELINE_DESCRIPTION') }}</p>
              </div>
              <NextButton v-if="isCreatingPipeline" ghost slate xs :label="$t('VIBEEXE_CRM.SETTINGS.CANCEL')" @click="selectPipeline(pipelines[0])" />
            </div>
            <div class="grid grid-cols-1 items-end gap-4 sm:grid-cols-[minmax(0,1fr)_auto_auto]">
              <Input v-model="pipelineForm.name" :label="$t('VIBEEXE_CRM.SETTINGS.NAME')" />
              <label class="flex h-10 items-center gap-2 rounded-lg border border-n-weak px-3 text-sm text-n-slate-12">
                <input v-model="pipelineForm.active" type="checkbox" />
                {{ $t('VIBEEXE_CRM.SETTINGS.ACTIVE') }}
              </label>
              <label class="flex h-10 items-center gap-2 rounded-lg border border-n-weak px-3 text-sm text-n-slate-12">
                <input v-model="pipelineForm.default" type="checkbox" />
                {{ $t('VIBEEXE_CRM.SETTINGS.DEFAULT') }}
              </label>
            </div>
            <div class="mt-4 flex flex-wrap gap-2">
              <NextButton icon="i-lucide-save" :is-loading="isSaving" :disabled="!pipelineForm.name.trim()" :label="$t('VIBEEXE_CRM.SETTINGS.SAVE_PIPELINE')" @click="savePipeline" />
              <NextButton v-if="selectedPipeline && !isCreatingPipeline && !selectedPipeline.default" outline slate icon="i-lucide-star" :label="$t('VIBEEXE_CRM.SETTINGS.SET_DEFAULT_PIPELINE')" @click="updatePipeline({ default: true })" />
              <NextButton v-if="selectedPipeline && !isCreatingPipeline" outline slate :icon="selectedPipeline.active ? 'i-lucide-eye-off' : 'i-lucide-eye'" :label="selectedPipeline.active ? $t('VIBEEXE_CRM.SETTINGS.DEACTIVATE') : $t('VIBEEXE_CRM.SETTINGS.ACTIVATE')" @click="updatePipeline({ active: !selectedPipeline.active })" />
              <NextButton v-if="selectedPipeline && !isCreatingPipeline" outline ruby icon="i-lucide-trash-2" :label="$t('VIBEEXE_CRM.SETTINGS.DELETE')" @click="requestDelete('pipeline', selectedPipeline)" />
            </div>
            <p
              v-if="selectedPipeline && (selectedPipeline.lead_count || selectedPipeline.inbox_default_count)"
              class="mt-4 rounded-lg bg-n-amber-3 px-3 py-2 text-sm text-n-amber-11"
            >
              {{ $t('VIBEEXE_CRM.SETTINGS.PIPELINE_DEPENDENCIES', {
                dependencies: dependencySummary(selectedPipeline.lead_count, selectedPipeline.inbox_default_count),
              }) }}
            </p>
          </section>

          <section v-if="selectedPipeline && !isCreatingPipeline" class="rounded-xl border border-n-weak bg-n-surface-1 p-5">
            <div class="mb-4 flex flex-wrap items-end justify-between gap-3">
              <div><h2 class="text-base font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.SETTINGS.STAGES') }}</h2><p class="mt-1 text-sm text-n-slate-10">{{ $t('VIBEEXE_CRM.SETTINGS.STAGES_DESCRIPTION') }}</p></div>
              <label class="flex flex-col gap-1 text-xs font-medium text-n-slate-11">{{ $t('VIBEEXE_CRM.SETTINGS.PIPELINE') }}<SelectInput v-model="selectedPipelineId" :options="pipelineOptions" @update:model-value="selectPipeline(pipelines.find(item => item.id === Number($event)))" /></label>
            </div>
            <div class="flex flex-col gap-3">
              <div
                v-for="(stage, index) in selectedStages"
                :key="stage.id"
                class="rounded-xl border border-n-weak bg-n-surface-2 p-4"
                data-testid="crm-stage-row"
              >
                <div class="grid grid-cols-1 items-end gap-4 md:grid-cols-2 xl:grid-cols-12">
                  <Input
                    :model-value="stage.name"
                    class="xl:col-span-5"
                    :label="$t('VIBEEXE_CRM.SETTINGS.STAGE_NAME')"
                    @blur="updateStage(stage, { name: $event.target.value })"
                  />
                  <label class="flex min-w-0 flex-col gap-1 text-sm font-medium text-n-slate-12 xl:col-span-3">
                    {{ $t('VIBEEXE_CRM.SETTINGS.STAGE_TYPE') }}
                    <SelectInput
                      :model-value="stage.stage_type"
                      :options="stageTypeOptions"
                      @update:model-value="updateStage(stage, { stage_type: $event })"
                    />
                  </label>
                  <Input
                    :model-value="stage.probability"
                    class="xl:col-span-2"
                    type="number"
                    min="0"
                    max="100"
                    :label="$t('VIBEEXE_CRM.SETTINGS.PROBABILITY')"
                    @blur="updateStage(stage, { probability: $event.target.value })"
                  />
                  <label class="flex h-10 items-center gap-2 rounded-lg px-2 text-sm text-n-slate-12 xl:col-span-2">
                    <input
                      :checked="stage.active"
                      type="checkbox"
                      @change="updateStage(stage, { active: $event.target.checked })"
                    />
                    {{ $t('VIBEEXE_CRM.SETTINGS.ACTIVE') }}
                  </label>
                </div>
                <div class="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-n-weak pt-3">
                  <div class="flex flex-wrap items-center gap-2 text-xs text-n-slate-10">
                    <NextButton
                      v-tooltip.top="$t('VIBEEXE_CRM.SETTINGS.MOVE_UP')"
                      ghost
                      slate
                      xs
                      icon="i-lucide-chevron-up"
                      :disabled="index === 0"
                      :aria-label="$t('VIBEEXE_CRM.SETTINGS.MOVE_UP')"
                      @click="moveStage(index, -1)"
                    />
                    <NextButton
                      v-tooltip.top="$t('VIBEEXE_CRM.SETTINGS.MOVE_DOWN')"
                      ghost
                      slate
                      xs
                      icon="i-lucide-chevron-down"
                      :disabled="index === selectedStages.length - 1"
                      :aria-label="$t('VIBEEXE_CRM.SETTINGS.MOVE_DOWN')"
                      @click="moveStage(index, 1)"
                    />
                    <span v-if="stage.default" class="rounded bg-n-blue-4 px-2 py-1 text-n-blue-11">
                      {{ $t('VIBEEXE_CRM.SETTINGS.START_STAGE') }}
                    </span>
                    <NextButton
                      v-else
                      ghost
                      slate
                      xs
                      icon="i-lucide-play"
                      :label="$t('VIBEEXE_CRM.SETTINGS.SET_START_STAGE')"
                      @click="updateStage(stage, { default: true })"
                    />
                    <span v-if="stage.lead_count || stage.inbox_default_count" class="text-n-amber-11">
                      {{ $t('VIBEEXE_CRM.SETTINGS.STAGE_DEPENDENCIES', {
                        dependencies: dependencySummary(stage.lead_count, stage.inbox_default_count),
                      }) }}
                    </span>
                  </div>
                  <NextButton
                    v-tooltip.top="$t('VIBEEXE_CRM.SETTINGS.DELETE')"
                    ghost
                    ruby
                    xs
                    icon="i-lucide-trash-2"
                    :aria-label="$t('VIBEEXE_CRM.SETTINGS.DELETE')"
                    @click="requestDelete('stage', stage)"
                  />
                </div>
              </div>
            </div>
            <div class="mt-5 rounded-lg border border-dashed border-n-strong p-4">
              <h3 class="mb-3 text-sm font-semibold text-n-slate-12">{{ $t('VIBEEXE_CRM.SETTINGS.ADD_STAGE') }}</h3>
              <div class="grid grid-cols-1 items-end gap-4 md:grid-cols-2 xl:grid-cols-12">
                <Input
                  v-model="stageForm.name"
                  class="xl:col-span-5"
                  :label="$t('VIBEEXE_CRM.SETTINGS.STAGE_NAME')"
                />
                <label class="flex min-w-0 flex-col gap-1 text-sm font-medium text-n-slate-12 xl:col-span-3">
                  {{ $t('VIBEEXE_CRM.SETTINGS.STAGE_TYPE') }}
                  <SelectInput v-model="stageForm.stage_type" :options="stageTypeOptions" />
                </label>
                <Input
                  v-model="stageForm.probability"
                  class="xl:col-span-2"
                  type="number"
                  min="0"
                  max="100"
                  :label="$t('VIBEEXE_CRM.SETTINGS.PROBABILITY')"
                />
                <label class="flex h-10 items-center gap-2 rounded-lg px-2 text-sm text-n-slate-12 xl:col-span-2">
                  <input v-model="stageForm.active" type="checkbox" />
                  {{ $t('VIBEEXE_CRM.SETTINGS.ACTIVE') }}
                </label>
              </div>
              <div class="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-n-weak pt-3">
                <label class="flex items-center gap-2 text-sm text-n-slate-12">
                  <input v-model="stageForm.default" type="checkbox" />
                  {{ $t('VIBEEXE_CRM.SETTINGS.USE_AS_START_STAGE') }}
                </label>
                <NextButton
                  icon="i-lucide-plus"
                  :disabled="!stageForm.name.trim()"
                  :label="$t('VIBEEXE_CRM.SETTINGS.ADD_STAGE')"
                  @click="saveStage"
                />
              </div>
            </div>
          </section>
        </main>
      </div>

      <Dialog
        ref="deleteDialog"
        type="alert"
        :title="$t('VIBEEXE_CRM.SETTINGS.DELETE_TITLE')"
        :description="deleteDescription"
        :confirm-button-label="$t('VIBEEXE_CRM.SETTINGS.DELETE')"
        :disable-confirm-button="deleteBlocked"
        @confirm="confirmDelete"
      />
    </div>
  </SettingsLayout>
</template>
