require 'application_system_test_case'

# Test data entry mode input
class DataEntryTest < ApplicationSystemTestCase
  before do
    @line = create :line
    @user = create :user
    @clinic = create :clinic
    create_insurance_config
    create_referred_by_config
    log_in_as @user
    visit data_entry_path
    has_text? 'PATIENT ENTRY' # wait until load
  end

  describe 'entering a new patient' do
    before do
      # fill out the form
      select @line.name, from: 'patient_line_id'
      fill_in 'Initial Call Date', with: 2.days.ago.strftime('%m/%d/%Y')
      fill_in 'Name', with: 'Susie Everyteen'
      fill_in 'Phone', with: '111-222-3344'
      fill_in 'Pronouns', with: 'she/they'
      fill_in 'Other contact name', with: 'Billy Everyteen'
      fill_in 'Other phone', with: '111-555-9999'
      fill_in 'Relationship to other contact', with: 'Friend'
      select '1 week', from: 'patient_last_menstrual_period_weeks'
      select '2 days', from: 'patient_last_menstrual_period_days'
      fill_in 'City', with: 'Washington'
      select 'DC', from: 'patient_state'
      fill_in 'County', with: 'Wash'
      fill_in 'Zipcode', with: '20009'
      fill_in 'CATF pledge', with: '100'
      fill_in 'Age', with: '30'
      select 'Other', from: 'patient_race_ethnicity'
      select @clinic.name, from: 'patient_clinic_id'
      fill_in 'Appointment date', with: 1.day.ago.strftime('%m/%d/%Y')
      select 'DC Medicaid', from: 'patient_insurance'
      select '1', from: 'patient_household_size_adults'
      select '2', from: 'patient_household_size_children'
      select 'Student', from: 'patient_employment_status'
      select 'Under $9,999 ($192/wk - $833/mo)', from: 'patient_income'
      select 'Clinic', from: 'patient_referred_by'
      fill_in 'Procedure Cost', with: '200'
      fill_in 'Patient contribution', with: '150'
      fill_in 'National Abortion Federation pledge', with: '50'
      select 'English', from: 'patient_language'
      select 'Do not leave a voicemail', from: 'patient_voicemail_preference'
      check 'patient_referred_to_clinic'
      check 'patient_completed_ultrasound'
      check 'Pledge Sent'
      check 'fetal_patient_special_circumstances'
      check 'home_patient_special_circumstances'
      click_button 'Create Patient'
      has_text? 'Patient information' # wait for redirect
    end

    it 'should log a new patient ready for further editing: dashboard' do
      within :css, '#patient_dashboard' do
        lmp_weeks = find('#patient_last_menstrual_period_weeks')
        lmp_days = find('#patient_last_menstrual_period_days')
        assert has_field? 'First and last name', with: 'Susie Everyteen'
        assert_equal '1', lmp_weeks.value
        assert_equal '2', lmp_days.value
        assert has_field? 'Pronouns', with: 'she/they'
        assert has_text? "Called on: #{2.days.ago.strftime('%m/%d/%Y')}"
        assert has_field?('Appointment date',
                          with: 1.day.ago.strftime('%Y-%m-%d'))
        assert has_field? 'Phone number', with: '111-222-3344'
      end
    end

    it 'should log a new patient ready for further editing: information' do
      within :css, '#patient_information' do
        assert has_field? 'Other contact name', with: 'Billy Everyteen'
        assert has_field? 'Other phone', with: '111-555-9999'
        assert has_field? 'Relationship to other contact', with: 'Friend'
        assert has_field? 'Age', with: '30'
        assert_equal 'Other', find('#patient_race_ethnicity').value
        assert has_field? 'City', with: 'Washington'
        assert_equal 'DC', find('#patient_state').value
        assert has_field? 'County', with: 'Wash'
        assert has_field? 'Zipcode', with: '20009'
        assert_equal 'English', find('#patient_language').text
        assert_equal 'no', find('#patient_voicemail_preference').value
        assert_equal 'Student', find('#patient_employment_status').value
        assert_equal 'Under $9,999',
                     find('#patient_income').value
        assert_equal '1', find('#patient_household_size_adults').value
        assert_equal '2', find('#patient_household_size_children').value
        assert_equal 'DC Medicaid', find('#patient_insurance').value
        assert_equal 'Clinic', find('#patient_referred_by').value
        assert has_checked_field? 'Fetal diagnosis'
        assert has_checked_field? 'Homelessness'
      end
    end

    it 'should log a new patient ready for further editing: abortion' do
      click_link 'Abortion Information'
      within :css, '#abortion_information' do
        assert_equal @clinic.id.to_s, find('#patient_clinic_id').value
        assert has_field? 'Abortion cost', with: '200'
        assert has_field? 'Patient contribution', with: '150'
        assert has_field? 'National Abortion Federation pledge', with: '50'
        assert has_field? 'CATF pledge', with: '100'
        assert has_checked_field? 'Referred to clinic'
        assert has_checked_field? 'Ultrasound completed?'
      end
    end

    it 'should show new patients pledge in the budget bar' do
      visit root_path

      within :css, '#budget_bar' do
        assert has_text? "$100 sent (1 patients)"
        assert has_text? "$0 pledged (0 patients)"
        refute has_text? "Susie Everyteen - appt on "
      end
    end
  end

  describe 'entering a new backdated patient' do
    before do
      # fill out the form
      select @line.name, from: 'patient_line_id'
      fill_in 'Initial Call Date', with: 90.days.ago.strftime('%m/%d/%Y')
      fill_in 'Name', with: 'Susie Backdated'
      fill_in 'Phone', with: '111-222-3345'
      fill_in 'Other contact name', with: 'Billy Everyteen'
      fill_in 'Other phone', with: '111-555-8888'
      fill_in 'Relationship to other contact', with: 'Friend'
      select '1 week', from: 'patient_last_menstrual_period_weeks'
      select '2 days', from: 'patient_last_menstrual_period_days'
      fill_in 'City', with: 'Washington'
      select 'DC', from: 'patient_state'
      fill_in 'County', with: 'Wash'
      fill_in 'CATF pledge', with: '99'
      fill_in 'Fund pledged at', with: 80.days.ago.strftime('%m/%d/%Y')
      fill_in 'Age', with: '30'
      select 'Other', from: 'patient_race_ethnicity'
      select @clinic.name, from: 'patient_clinic_id'
      fill_in 'Appointment date', with: 70.days.ago.strftime('%m/%d/%Y')
      select 'DC Medicaid', from: 'patient_insurance'
      select '1', from: 'patient_household_size_adults'
      select '2', from: 'patient_household_size_children'
      select 'Student', from: 'patient_employment_status'
      select 'Under $9,999 ($192/wk - $833/mo)', from: 'patient_income'
      select 'Clinic', from: 'patient_referred_by'
      fill_in 'Procedure Cost', with: '200'
      fill_in 'Patient contribution', with: '51'
      fill_in 'National Abortion Federation pledge', with: '50'
      select 'English', from: 'patient_language'
      select 'Do not leave a voicemail', from: 'patient_voicemail_preference'
      check 'patient_referred_to_clinic'
      check 'patient_completed_ultrasound'
      check 'Pledge Sent'
      fill_in 'Pledge sent at:', with: 75.days.ago.strftime('%m/%d/%Y')
      check 'fetal_patient_special_circumstances'
      check 'home_patient_special_circumstances'
      click_button 'Create Patient'
      has_text? 'Patient information' # wait for redirect
    end

    it 'should show backdated new patient in the budget bar' do
      visit root_path

      within :css, '#budget_bar' do
        assert has_text? "$99 sent (1 patients)"
        assert has_text? "$0 pledged (0 patients)"
        refute has_text? "$0 sent"
      end
    end
  end

  describe 'entering bad data' do
    describe 'bad phone' do
      before do
        create :patient, primary_phone: '111-111-1111'

        select @line.name, from: 'patient_line_id'
        fill_in 'Initial Call Date', with: 2.days.ago.strftime('%m/%d/%Y')
        fill_in 'Name', with: 'Susie Everyteen'
        fill_in 'Phone', with: '111-111-1111'
        click_button 'Create Patient'
      end

      it 'should return an error on a duplicate phone' do
        assert has_text? 'This phone number is already taken'
        assert_equal current_path, data_entry_path
      end
    end

    describe 'pledge with insufficient other info' do
      before do
        select @line.name, from: 'patient_line_id'
        fill_in 'Initial Call Date', with: 2.days.ago.strftime('%m/%d/%Y')
        fill_in 'Name', with: 'Susie Everyteen'
        fill_in 'Phone', with: '111-222-3344'
        check 'Pledge Sent'
        click_button 'Create Patient'
      end

      it 'should return an error on insufficient pledge sent data' do
        assert has_text? 'Errors prevented this patient from being saved'
        assert_equal current_path, data_entry_path
      end
    end
  end
end
