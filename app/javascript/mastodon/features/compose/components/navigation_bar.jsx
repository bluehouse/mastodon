import PropTypes from 'prop-types';

import ImmutablePropTypes from 'react-immutable-proptypes';

import Account from 'mastodon/components/account';

import ActionBar from './action_bar';

export const NavigationBar = ({ account, onLogout }) => (
  <div className='navigation-bar'>
    <Account account={account} minimal />
    <ActionBar account={account} onLogout={onLogout} />
  </div>
);

NavigationBar.propTypes = {
  account: ImmutablePropTypes.map.isRequired,
  onLogout: PropTypes.func.isRequired,
};
