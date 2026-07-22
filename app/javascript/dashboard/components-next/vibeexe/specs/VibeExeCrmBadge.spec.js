import { mount } from '@vue/test-utils';
import VibeExeCrmBadge from '../VibeExeCrmBadge.vue';

describe('VibeExeCrmBadge', () => {
  it.each([
    ['open', 'Open'],
    ['won', 'Won'],
    ['urgent', 'Urgent'],
    ['web_widget', 'Web widget'],
  ])('renders a readable label for %s', (value, label) => {
    const wrapper = mount(VibeExeCrmBadge, { props: { value } });

    expect(wrapper.text()).toBe(label);
  });

  it('renders an intentional missing value', () => {
    const wrapper = mount(VibeExeCrmBadge);

    expect(wrapper.text()).toBe('—');
  });
});
