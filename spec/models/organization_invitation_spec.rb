require 'rails_helper'

RSpec.describe OrganizationInvitation, type: :model do
  let(:organization) { create(:organization) }

  around do |example|
    ActsAsTenant.with_tenant(organization) do
      example.run
    end
  end

  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:invited_by).class_name('User') }
  end

  describe 'validations' do
    subject { build(:organization_invitation, organization: organization) }

    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(%w[viewer member admin]) }

    it 'validates email format' do
      invitation = build(:organization_invitation, organization: organization, email: 'invalid-email')
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to be_present
    end

    it 'validates uniqueness of token' do
      existing = create(:organization_invitation, organization: organization)
      duplicate = build(:organization_invitation, organization: organization, token: existing.token)
      expect(duplicate).not_to be_valid
    end

    it 'ensures token is present after validation' do
      invitation = build(:organization_invitation, organization: organization, token: nil)
      invitation.valid?
      expect(invitation.token).to be_present
    end

    it 'ensures expires_at is present after validation' do
      invitation = build(:organization_invitation, organization: organization, expires_at: nil)
      invitation.valid?
      expect(invitation.expires_at).to be_present
    end
  end

  describe 'callbacks' do
    it 'generates a token before validation on create' do
      invitation = build(:organization_invitation, organization: organization, token: nil)
      invitation.valid?
      expect(invitation.token).to be_present
    end

    it 'sets expiration before validation on create' do
      invitation = build(:organization_invitation, organization: organization, expires_at: nil)
      invitation.valid?
      expect(invitation.expires_at).to be_present
      expect(invitation.expires_at).to be > Time.current
    end

    it 'normalizes email before validation' do
      invitation = build(:organization_invitation, organization: organization, email: '  TEST@EXAMPLE.COM  ')
      invitation.valid?
      expect(invitation.email).to eq('test@example.com')
    end
  end

  describe 'scopes' do
    let!(:pending_invitation) { create(:organization_invitation, organization: organization) }
    let!(:expired_invitation) { create(:organization_invitation, :expired, organization: organization) }
    let!(:accepted_invitation) { create(:organization_invitation, :accepted, organization: organization) }

    describe '.pending' do
      it 'returns only pending invitations' do
        expect(OrganizationInvitation.pending).to include(pending_invitation)
        expect(OrganizationInvitation.pending).not_to include(expired_invitation)
        expect(OrganizationInvitation.pending).not_to include(accepted_invitation)
      end
    end
  end

  describe '#expired?' do
    it 'returns true when invitation has expired' do
      invitation = build(:organization_invitation, :expired)
      expect(invitation.expired?).to be true
    end

    it 'returns false when invitation has not expired' do
      invitation = build(:organization_invitation)
      expect(invitation.expired?).to be false
    end

    it 'returns false when invitation has been accepted' do
      invitation = build(:organization_invitation, :accepted)
      expect(invitation.expired?).to be false
    end
  end

  describe '#accepted?' do
    it 'returns true when invitation has been accepted' do
      invitation = build(:organization_invitation, :accepted)
      expect(invitation.accepted?).to be true
    end

    it 'returns false when invitation has not been accepted' do
      invitation = build(:organization_invitation)
      expect(invitation.accepted?).to be false
    end
  end

  describe '#accept!' do
    let(:invitation) { create(:organization_invitation, organization: organization) }
    let(:user) { create(:user, email: invitation.email) }

    context 'with valid invitation' do
      it 'marks invitation as accepted' do
        expect {
          invitation.accept!(user)
        }.to change { invitation.reload.accepted_at }.from(nil)
      end

      it 'creates organization membership' do
        expect {
          invitation.accept!(user)
        }.to change { OrganizationMembership.count }.by(1)
      end

      it 'creates membership with correct role' do
        invitation.accept!(user)
        membership = OrganizationMembership.find_by(user: user, organization: organization)
        expect(membership.role).to eq(invitation.role)
      end

      it 'returns true' do
        expect(invitation.accept!(user)).to be true
      end
    end

    context 'with expired invitation' do
      let(:invitation) { create(:organization_invitation, :expired, organization: organization) }

      it 'does not accept the invitation' do
        expect(invitation.accept!(user)).to be false
        expect(invitation.reload.accepted_at).to be_nil
      end

      it 'does not create membership' do
        expect {
          invitation.accept!(user)
        }.not_to change { OrganizationMembership.count }
      end
    end

    context 'with already accepted invitation' do
      let(:invitation) { create(:organization_invitation, :accepted, organization: organization) }

      it 'does not accept again' do
        original_time = invitation.accepted_at
        invitation.accept!(user)
        expect(invitation.reload.accepted_at).to eq(original_time)
      end

      it 'does not create duplicate membership' do
        expect {
          invitation.accept!(user)
        }.not_to change { OrganizationMembership.count }
      end
    end
  end
end
