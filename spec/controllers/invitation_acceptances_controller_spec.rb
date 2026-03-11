require 'rails_helper'

RSpec.describe InvitationAcceptancesController, type: :controller do
  let(:organization) { create(:organization) }
  let(:inviter) { create(:user) }
  let(:invitation) { create(:organization_invitation, organization: organization, invited_by: inviter) }

  describe 'GET #show' do
    context 'with valid token' do
      context 'when user is not signed in and account does not exist' do
        it 'renders the new_user template' do
          get :show, params: { token: invitation.token }
          expect(response).to render_template(:new_user)
        end

        it 'assigns a new user with the invitation email' do
          get :show, params: { token: invitation.token }
          expect(assigns(:user).email).to eq(invitation.email)
        end
      end

      context 'when user is not signed in but account exists' do
        let!(:existing_user) { create(:user, email: invitation.email) }

        it 'redirects to sign in' do
          get :show, params: { token: invitation.token }
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'when user is signed in with matching email' do
        let(:user) { create(:user, email: invitation.email) }

        before { sign_in user }

        it 'renders the show template' do
          get :show, params: { token: invitation.token }
          expect(response).to render_template(:show)
        end
      end

      context 'when user is signed in with different email' do
        let(:user) { create(:user, email: 'different@example.com') }

        before { sign_in user }

        it 'signs out the user and redirects to sign in' do
          get :show, params: { token: invitation.token }
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'when invitation is expired' do
        let(:invitation) { create(:organization_invitation, :expired, organization: organization, invited_by: inviter) }

        it 'renders the expired template' do
          get :show, params: { token: invitation.token }
          expect(response).to render_template(:expired)
        end
      end

      context 'when invitation is already accepted' do
        let(:invitation) { create(:organization_invitation, :accepted, organization: organization, invited_by: inviter) }

        it 'renders the already_accepted template' do
          get :show, params: { token: invitation.token }
          expect(response).to render_template(:already_accepted)
        end
      end
    end

    context 'with invalid token' do
      it 'renders not_found template' do
        get :show, params: { token: 'invalid-token' }
        expect(response).to have_http_status(:not_found)
        expect(response).to render_template(:not_found)
      end
    end
  end

  describe 'POST #accept' do
    let(:user) { create(:user, email: invitation.email) }

    before { sign_in user }

    context 'with valid invitation' do
      it 'accepts the invitation' do
        post :accept, params: { token: invitation.token }
        expect(invitation.reload.accepted?).to be true
      end

      it 'creates organization membership' do
        expect {
          post :accept, params: { token: invitation.token }
        }.to change { OrganizationMembership.count }.by(1)
      end

      it 'redirects to organization dashboard' do
        post :accept, params: { token: invitation.token }
        expect(response).to redirect_to(org_prompt_tracker.root_path(org_slug: organization.slug))
      end
    end

    context 'when not signed in' do
      before { sign_out user }

      it 'redirects to invitation page' do
        post :accept, params: { token: invitation.token }
        expect(response).to redirect_to(invitation_path(invitation.token))
      end
    end

    context 'with expired invitation' do
      let(:invitation) { create(:organization_invitation, :expired, organization: organization, invited_by: inviter) }

      it 'does not accept the invitation' do
        post :accept, params: { token: invitation.token }
        expect(invitation.reload.accepted?).to be false
      end
    end
  end

  describe 'POST #create_account' do
    let(:user_params) do
      {
        first_name: 'John',
        last_name: 'Doe',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    context 'with valid params' do
      it 'creates a new user' do
        expect {
          post :create_account, params: { token: invitation.token, user: user_params }
        }.to change { User.count }.by(1)
      end

      it 'creates user with invitation email' do
        post :create_account, params: { token: invitation.token, user: user_params }
        user = User.last
        expect(user.email).to eq(invitation.email)
      end

      it 'auto-confirms the user' do
        post :create_account, params: { token: invitation.token, user: user_params }
        user = User.last
        expect(user.confirmed?).to be true
      end
    end
  end
end

