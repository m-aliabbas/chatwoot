import { mount } from '@vue/test-utils';
import VibeExeDetailField from '../VibeExeDetailField.vue';

describe('VibeExeDetailField', () => {
  it('associates a visible label with its value', () => {
    const wrapper = mount(VibeExeDetailField, {
      props: { label: 'Owner', value: 'Jane' },
    });

    expect(wrapper.find('dt').text()).toBe('Owner');
    expect(wrapper.find('dd').text()).toBe('Jane');
  });

  it('styles missing values consistently', () => {
    const wrapper = mount(VibeExeDetailField, {
      props: { label: 'Team' },
    });

    expect(wrapper.find('dd').text()).toBe('—');
  });
});
