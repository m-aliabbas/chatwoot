import { flushPromises, shallowMount } from '@vue/test-utils';
import CrmPipelineSettings from '../CrmPipelineSettings.vue';
import VibeExeCrmAPI from 'dashboard/api/vibeexeCrm';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/api/vibeexeCrm', () => ({
  default: {
    getAllPipelines: vi.fn(),
    bootstrapDefaultPipeline: vi.fn(),
  },
}));

const mountComponent = () =>
  shallowMount(CrmPipelineSettings, {
    global: {
      mocks: { $t: key => key },
      stubs: {
        SettingsLayout: { template: '<div><slot /></div>' },
        BaseSettingsHeader: true,
        NextButton: {
          props: ['label'],
          template: '<button @click="$emit(\'click\')">{{ label }}</button>',
        },
      },
    },
  });

describe('CrmPipelineSettings', () => {
  beforeEach(() => {
    VibeExeCrmAPI.getAllPipelines.mockResolvedValue({ data: [] });
  });

  it('shows the explicit no-pipeline empty state', async () => {
    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.find('[data-testid="crm-pipeline-empty-state"]').exists()).toBe(true);
    expect(wrapper.text()).toContain('VIBEEXE_CRM.SETTINGS.EMPTY_TITLE');
  });

  it('bootstraps the default pipeline from the empty state', async () => {
    VibeExeCrmAPI.bootstrapDefaultPipeline.mockResolvedValue({ data: { pipeline: { id: 1 } } });
    const wrapper = mountComponent();
    await flushPromises();

    await wrapper.find('button').trigger('click');
    await flushPromises();

    expect(VibeExeCrmAPI.bootstrapDefaultPipeline).toHaveBeenCalledOnce();
  });
});
