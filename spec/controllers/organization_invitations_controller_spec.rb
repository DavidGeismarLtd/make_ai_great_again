require 'rails_helper'

RSpec.describe OrganizationInvitationsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:admin_user) { create(:user) }
  let!(:admin_membership) do
    ActsAsTenant.with_tenant(organization) do
      create(:organization_membership, organization: organization, user: admin_user, role: 'admin')
    end
  end

  before do
    ActsAsTenant.current_tenant = organization
    sign_in admin_user, scope: :user
  end

  describe 'GET #index' do
    let!(:pending_invitation) { create(:organization_invitation, organization: organization, invited_by: admin_user) }
    let!(:accepted_invitation) { create(:organization_invitation, :accepted, organization: organization, invited_by: admin_user) }

    it 'returns http success' do
      get :index, params: { org_slug: organization.slug }
      expect(response).to have_http_status(:success)
    end

    it 'assigns pending invitations' do
      get :index, params: { org_slug: organization.slug }
      expect(assigns(:pending_invitations)).to include(pending_invitation)
      expect(assigns(:pending_invitations)).not_to include(accepted_invitation)
    end

    it 'assigns accepted invitations' do
      get :index, params: { org_slug: organization.slug }
      expect(assigns(:accepted_invitations)).to include(accepted_invitation)
      expect(assigns(:accepted_invitations)).not_to include(pending_invitation)
    end
  end

  describe 'GET #new' do
    it 'returns http success' do
      get :new, params: { org_slug: organization.slug }
      expect(response).to have_http_status(:success)
    end

    it 'assigns a new invitation' do
      get :new, params: { org_slug: organization.slug }
      expect(assigns(:invitation)).to be_a_new(OrganizationInvitation)
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        org_slug: organization.slug,
        organization_invitation: {
          email: 'newuser@example.com',
          role: 'member'
        }
      }
    end

    context 'with valid params' do
      it 'creates a new invitation' do
        expect {
          post :create, params: valid_params
        }.to change { OrganizationInvitation.count }.by(1)
      end

      it 'sends an invitation email' do
        expect {
          post :create, params: valid_params
        }.to have_enqueued_mail(OrganizationInvitationMailer, :invite)
      end

      it 'redirects to invitations index' do
        post :create, params: valid_params
        expect(response).to redirect_to(org_organization_invitations_path(org_slug: organization.slug))
      end

      it 'sets the invited_by to current user' do
        post :create, params: valid_params
        invitation = OrganizationInvitation.last
        expect(invitation.invited_by).to eq(admin_user)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          org_slug: organization.slug,
          organization_invitation: {
            email: 'invalid-email',
            role: 'member'
          }
        }
      end

      it 'does not create an invitation' do
        expect {
          post :create, params: invalid_params
        }.not_to change { OrganizationInvitation.count }
      end

      it 'renders the new template' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'POST #resend' do
    let(:invitation) { create(:organization_invitation, organization: organization, invited_by: admin_user) }

    it 'sends the invitation email again' do
      expect {
        post :resend, params: { org_slug: organization.slug, id: invitation.id }
      }.to have_enqueued_mail(OrganizationInvitationMailer, :invite)
    end

    it 'redirects to invitations index' do
      post :resend, params: { org_slug: organization.slug, id: invitation.id }
      expect(response).to redirect_to(org_organization_invitations_path(org_slug: organization.slug))
    end
  end

  describe 'DELETE #destroy' do
    let!(:invitation) { create(:organization_invitation, organization: organization, invited_by: admin_user) }

    it 'destroys the invitation' do
      expect {
        delete :destroy, params: { org_slug: organization.slug, id: invitation.id }
      }.to change { OrganizationInvitation.count }.by(-1)
    end

    it 'redirects to invitations index' do
      delete :destroy, params: { org_slug: organization.slug, id: invitation.id }
      expect(response).to redirect_to(org_organization_invitations_path(org_slug: organization.slug))
    end
  end

  context 'authorization' do
    let(:member_user) { create(:user) }
    let!(:member_membership) do
      ActsAsTenant.with_tenant(organization) do
        create(:organization_membership, organization: organization, user: member_user, role: 'member')
      end
    end

    before do
      sign_out admin_user
      sign_in member_user
    end

    it 'does not allow members to access invitations' do
      get :index, params: { org_slug: organization.slug }
      expect(response).to have_http_status(:redirect)
    end
  end
end
