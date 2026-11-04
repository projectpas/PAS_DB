/*************************************************************
 ** File:   [USP_GetLeaseAgreementPDFData]
 ** Description: Values SAVED WITH ONE agreement (dbo.LeaseAgreement row) for the dynamic fields (##TAGS##) of the PDF.
 **              Returns ONE row. EVERY COLUMN NAME IS A TAG OF THE 'LeaseAgreement' EMAIL TEMPLATE WITHOUT THE ## (column
 **              SECURITY_DEPOSIT_AMOUNT fills ##SECURITY_DEPOSIT_AMOUNT##). The API replaces every tag with the same column
 **              name, so a new dynamic field = add one column here (and to the table), no API change. Dates are returned
 **              as MM/dd/yyyy text and amounts as text with 2 decimals, ready to print.
 **
 **              The values that come from the lease / customer / stockline (lessee, engine, rent, currency, ...) are returned by
 **              USP_GetLeaseAgreementData and the LESSOR_* values come from the company header; the API merges them: the value
 **              of the database wins, the value typed in the agreement (same tag, saved in the column of this table) is used
 **              only when the database has none.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    02/11/2026     Rajesh Gami             [PN-18468] Created - Lease Agreement PDF dynamic values
    2    02/11/2026     Rajesh Gami             [PN-18468] Values typed in the agreement (terms, exhibits, ...) returned as tags
    3    02/11/2026     Rajesh Gami             [PN-18468] Lease / customer / engine values moved to USP_GetLeaseAgreementData

exec USP_GetLeaseAgreementPDFData @LeaseAgreementId=1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseAgreementPDFData]
	@LeaseAgreementId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		SELECT TOP 1
			-- ---- agreement / lease (extra info, not all are tags of the template) ----
			LA.[LeaseAgreementId]                                  AS LEASE_AGREEMENT_ID,
			LA.[VersionNo]                                         AS AGREEMENT_VERSION_NO,
			LA.[LeaseHeaderId]                                     AS LEASE_HEADER_ID,
			LA.[LeaseStocklineId]                                  AS LEASE_STOCKLINE_ID,
			ISNULL(LA.[LeaseNumber], '')                           AS LEASE_NUMBER,
			ISNULL(LA.[LeaseName], '')                             AS LEASE_NAME,
			LH.[ManagementStructureId]                             AS MANAGEMENT_STRUCTURE_ID,
			LA.[MasterCompanyId]                                   AS MASTER_COMPANY_ID,
			ISNULL(LA.[SalesPersonName], '')                       AS SALES_PERSON_NAME,
			ISNULL(LA.[SellerName], '')                            AS SELLER_NAME,
			ISNULL(LA.[StocklineNumber], '')                       AS STOCKLINE_NUMBER,
			ISNULL(LA.[Condition], '')                             AS ENGINE_CONDITION,
			ISNULL(LA.[PartDescription], '')                       AS ENGINE_DESCRIPTION,
			-- ---- effective date: "made this ##EFFECTIVE_DAY##<sup>##EFFECTIVE_DAY_SUFFIX##</sup> day of ##EFFECTIVE_MONTH_YEAR##" (13 + th, like the sample PDF) ----
			CASE WHEN LA.[AgreementDate] IS NULL THEN '' ELSE CAST(DAY(LA.[AgreementDate]) AS VARCHAR(2)) END AS EFFECTIVE_DAY,
			CASE WHEN LA.[AgreementDate] IS NULL THEN ''
				 WHEN DAY(LA.[AgreementDate]) IN (11, 12, 13) THEN 'th'
				 WHEN DAY(LA.[AgreementDate]) % 10 = 1 THEN 'st'
				 WHEN DAY(LA.[AgreementDate]) % 10 = 2 THEN 'nd'
				 WHEN DAY(LA.[AgreementDate]) % 10 = 3 THEN 'rd'
				 ELSE 'th' END                                     AS EFFECTIVE_DAY_SUFFIX,
			CASE WHEN LA.[AgreementDate] IS NULL THEN ''
				 ELSE DATENAME(MONTH, LA.[AgreementDate]) + ', ' + CAST(YEAR(LA.[AgreementDate]) AS VARCHAR(4)) END AS EFFECTIVE_MONTH_YEAR,
			ISNULL(CONVERT(VARCHAR(10), LA.[AgreementDate], 101), '')    AS AGREEMENT_DATE,
			ISNULL(CONVERT(VARCHAR(10), LA.[AgreementDueDate], 101), '') AS INITIAL_EXPIRATION_DATE,
			-- ---- values typed in the agreement (columns of LeaseAgreement) ----
			ISNULL(LA.[LessorEntityJurisdictionType], '') AS LESSOR_ENTITY_JURISDICTION_TYPE,
			ISNULL(LA.[LesseeEntityJurisdictionType], '') AS LESSEE_ENTITY_JURISDICTION_TYPE,
			ISNULL(LA.[LeasePurpose], '') AS LEASE_PURPOSE,
			ISNULL(LA.[EngineTsn], '') AS ENGINE_TSN,
			ISNULL(LA.[EngineCsn], '') AS ENGINE_CSN,
			CASE WHEN LA.[InsuredValue] IS NULL THEN '' ELSE FORMAT(LA.[InsuredValue], 'N2') END AS INSURED_VALUE,
			ISNULL(LA.[AircraftManufacturer], '') AS AIRCRAFT_MANUFACTURER,
			ISNULL(LA.[AircraftTypeModel], '') AS AIRCRAFT_TYPE_MODEL,
			ISNULL(LA.[AircraftRegistration], '') AS AIRCRAFT_REGISTRATION,
			ISNULL(LA.[AircraftSerialNumber], '') AS AIRCRAFT_SERIAL_NUMBER,
			ISNULL(LA.[ExtensionOptions], '') AS EXTENSION_OPTIONS,
			ISNULL(CAST(LA.[ExtensionNoticeDays] AS VARCHAR(20)), '') AS EXTENSION_NOTICE_DAYS,
			ISNULL(LA.[ReturnShippingLocation], '') AS RETURN_SHIPPING_LOCATION,
			ISNULL(CAST(LA.[ReturnDeliveryDays] AS VARCHAR(20)), '') AS RETURN_DELIVERY_DAYS,
			CASE WHEN LA.[SecurityDepositAmount] IS NULL THEN '' ELSE FORMAT(LA.[SecurityDepositAmount], 'N2') END AS SECURITY_DEPOSIT_AMOUNT,
			CASE WHEN LA.[FlightHourRate] IS NULL THEN '' ELSE FORMAT(LA.[FlightHourRate], 'N2') END AS FLIGHT_HOUR_RATE,
			CASE WHEN LA.[CycleRate] IS NULL THEN '' ELSE FORMAT(LA.[CycleRate], 'N2') END AS CYCLE_RATE,
			CASE WHEN LA.[LeaseInceptionFee] IS NULL THEN '' ELSE FORMAT(LA.[LeaseInceptionFee], 'N2') END AS LEASE_INCEPTION_FEE,
			ISNULL(LA.[LeaseInceptionFeeStatus], '') AS LEASE_INCEPTION_FEE_STATUS,
			CASE WHEN LA.[LeaseReturnFee] IS NULL THEN '' ELSE FORMAT(LA.[LeaseReturnFee], 'N2') END AS LEASE_RETURN_FEE,
			CASE WHEN LA.[DefaultDailyRate] IS NULL THEN '' ELSE FORMAT(LA.[DefaultDailyRate], 'N2') END AS DEFAULT_DAILY_RATE,
			CASE WHEN LA.[DefaultHourlyRate] IS NULL THEN '' ELSE FORMAT(LA.[DefaultHourlyRate], 'N2') END AS DEFAULT_HOURLY_RATE,
			CASE WHEN LA.[DefaultCycleRate] IS NULL THEN '' ELSE FORMAT(LA.[DefaultCycleRate], 'N2') END AS DEFAULT_CYCLE_RATE,
			ISNULL(CAST(LA.[LateReturnGraceDays] AS VARCHAR(20)), '') AS LATE_RETURN_GRACE_DAYS,
			CASE WHEN LA.[LateReturnDailyCharge] IS NULL THEN '' ELSE FORMAT(LA.[LateReturnDailyCharge], 'N2') END AS LATE_RETURN_DAILY_CHARGE,
			ISNULL(LA.[UsageReportingDay], '') AS USAGE_REPORTING_DAY,
			ISNULL(LA.[PaymentDueRule], '') AS PAYMENT_DUE_RULE,
			ISNULL(CAST(LA.[LateFeeGraceDays] AS VARCHAR(20)), '') AS LATE_FEE_GRACE_DAYS,
			CASE WHEN LA.[LatePaymentFee] IS NULL THEN '' ELSE FORMAT(LA.[LatePaymentFee], 'N2') END AS LATE_PAYMENT_FEE,
			ISNULL(CAST(LA.[InterestTriggerDays] AS VARCHAR(20)), '') AS INTEREST_TRIGGER_DAYS,
			ISNULL(LA.[MonthlyInterestRate], '') AS MONTHLY_INTEREST_RATE,
			ISNULL(CAST(LA.[CollectionTriggerDays] AS VARCHAR(20)), '') AS COLLECTION_TRIGGER_DAYS,
			ISNULL(LA.[PaymentMailingInstructions], '') AS PAYMENT_MAILING_INSTRUCTIONS,
			ISNULL(LA.[PaymentWireInstructions], '') AS PAYMENT_WIRE_INSTRUCTIONS,
			ISNULL(LA.[DeliveryLocation], '') AS DELIVERY_LOCATION,
			ISNULL(LA.[ReturnLocation], '') AS RETURN_LOCATION,
			ISNULL(CAST(LA.[ReturnTransitDays] AS VARCHAR(20)), '') AS RETURN_TRANSIT_DAYS,
			CASE WHEN LA.[FuelFilterCapCharge] IS NULL THEN '' ELSE FORMAT(LA.[FuelFilterCapCharge], 'N2') END AS FUEL_FILTER_CAP_CHARGE,
			ISNULL(LA.[ApprovedOilAnalysisKit], '') AS APPROVED_OIL_ANALYSIS_KIT,
			ISNULL(LA.[ReturnInspectionRequirement], '') AS RETURN_INSPECTION_REQUIREMENT,
			CASE WHEN LA.[ReturnInspectionRatePerHour] IS NULL THEN '' ELSE FORMAT(LA.[ReturnInspectionRatePerHour], 'N2') END AS RETURN_INSPECTION_RATE_PER_HOUR,
			CASE WHEN LA.[ReturnInspectionMaxCharge] IS NULL THEN '' ELSE FORMAT(LA.[ReturnInspectionMaxCharge], 'N2') END AS RETURN_INSPECTION_MAX_CHARGE,
			CASE WHEN LA.[MissingDataSheetCharge] IS NULL THEN '' ELSE FORMAT(LA.[MissingDataSheetCharge], 'N2') END AS MISSING_DATA_SHEET_CHARGE,
			ISNULL(CAST(LA.[SecurityDepositRefundDays] AS VARCHAR(20)), '') AS SECURITY_DEPOSIT_REFUND_DAYS,
			ISNULL(CAST(LA.[SoapTriggerHours] AS VARCHAR(20)), '') AS SOAP_TRIGGER_HOURS,
			ISNULL(CAST(LA.[SoapCompletionHoursAfterRemoval] AS VARCHAR(20)), '') AS SOAP_COMPLETION_HOURS_AFTER_REMOVAL,
			CASE WHEN LA.[SoapMissingReportCharge] IS NULL THEN '' ELSE FORMAT(LA.[SoapMissingReportCharge], 'N2') END AS SOAP_MISSING_REPORT_CHARGE,
			ISNULL(CAST(LA.[DefaultCureDays] AS VARCHAR(20)), '') AS DEFAULT_CURE_DAYS,
			ISNULL(LA.[NoticeDeliveryMethod], '') AS NOTICE_DELIVERY_METHOD,
			ISNULL(LA.[GoverningLawState], '') AS GOVERNING_LAW_STATE,
			ISNULL(LA.[LesseeSignatoryTitle], '') AS LESSEE_SIGNATORY_TITLE,
			ISNULL(LA.[LessorSignatoryName], '') AS LESSOR_SIGNATORY_NAME,
			ISNULL(LA.[LessorSignatoryTitle], '') AS LESSOR_SIGNATORY_TITLE,
			CASE WHEN LA.[LesseeSignatureDate] IS NULL THEN '' ELSE CONVERT(VARCHAR(10), LA.[LesseeSignatureDate], 101) END AS LESSEE_SIGNATURE_DATE,
			CASE WHEN LA.[LessorSignatureDate] IS NULL THEN '' ELSE CONVERT(VARCHAR(10), LA.[LessorSignatureDate], 101) END AS LESSOR_SIGNATURE_DATE,
			ISNULL(LA.[LessorFax], '') AS LESSOR_FAX,
			ISNULL(LA.[MinimumAircraftLiabilityCoverage], '') AS MINIMUM_AIRCRAFT_LIABILITY_COVERAGE,
			ISNULL(LA.[InsuranceCertificateHolder], '') AS INSURANCE_CERTIFICATE_HOLDER,
			ISNULL(CAST(LA.[CancellationNoticeDays] AS VARCHAR(20)), '') AS CANCELLATION_NOTICE_DAYS,
			ISNULL(CAST(LA.[NonpaymentCancellationNoticeDays] AS VARCHAR(20)), '') AS NONPAYMENT_CANCELLATION_NOTICE_DAYS,
			ISNULL(CAST(LA.[IncidentReportHours] AS VARCHAR(20)), '') AS INCIDENT_REPORT_HOURS,
			ISNULL(LA.[BetaSwitchSupplyStatus], '') AS BETA_SWITCH_SUPPLY_STATUS,
			ISNULL(LA.[NtsSwitchSupplyStatus], '') AS NTS_SWITCH_SUPPLY_STATUS,
			ISNULL(LA.[TempCompensatorSupplyStatus], '') AS TEMP_COMPENSATOR_SUPPLY_STATUS,
			ISNULL(LA.[CompFlowDividerInterval], '') AS COMP_FLOW_DIVIDER_INTERVAL,
			ISNULL(LA.[LessorLegalName], '') AS LESSOR_LEGAL_NAME,
			ISNULL(LA.[LessorAddress], '') AS LESSOR_ADDRESS,
			ISNULL(LA.[LessorPhone], '') AS LESSOR_PHONE,
			ISNULL(LA.[LessorNoticeEmail], '') AS LESSOR_NOTICE_EMAIL,
			ISNULL(LA.[LesseeLegalName], '') AS LESSEE_LEGAL_NAME,
			ISNULL(LA.[LesseeAddress], '') AS LESSEE_ADDRESS,
			ISNULL(LA.[LesseeNoticeEmail], '') AS LESSEE_NOTICE_EMAIL,
			ISNULL(LA.[LesseeSignatoryName], '') AS LESSEE_SIGNATORY_NAME,
			ISNULL(LA.[PurchaseOrderNumber], '') AS PURCHASE_ORDER_NUMBER,
			ISNULL(LA.[EngineManufacturer], '') AS ENGINE_MANUFACTURER,
			ISNULL(LA.[EngineModelNumber], '') AS ENGINE_MODEL_NUMBER,
			ISNULL(LA.[EngineSerialNumber], '') AS ENGINE_SERIAL_NUMBER,
			ISNULL(LA.[Currency], '') AS CURRENCY,
			ISNULL(LA.[PaymentCurrency], '') AS PAYMENT_CURRENCY,
			CASE WHEN LA.[MonthlyRentAmount] IS NULL THEN '' ELSE FORMAT(LA.[MonthlyRentAmount], 'N2') END AS MONTHLY_RENT_AMOUNT,
			CASE WHEN LA.[PreRemovalStatusDate] IS NULL THEN '' ELSE CONVERT(VARCHAR(10), LA.[PreRemovalStatusDate], 101) END AS PRE_REMOVAL_STATUS_DATE,
			ISNULL(LA.[PressureAltitude], '') AS PRESSURE_ALTITUDE,
			ISNULL(LA.[Oat], '') AS OAT,
			ISNULL(LA.[EgtCompensatorSetting], '') AS EGT_COMPENSATOR_SETTING,
			ISNULL(LA.[BleedAirValve], '') AS BLEED_AIR_VALVE,
			ISNULL(LA.[TargetTorque], '') AS TARGET_TORQUE,
			ISNULL(LA.[ActualTorque], '') AS ACTUAL_TORQUE,
			ISNULL(LA.[TargetTemperature], '') AS TARGET_TEMPERATURE,
			ISNULL(LA.[ActualTemperature], '') AS ACTUAL_TEMPERATURE,
			ISNULL(LA.[TargetFuelFlow], '') AS TARGET_FUEL_FLOW,
			ISNULL(LA.[ActualFuelFlow], '') AS ACTUAL_FUEL_FLOW,
			ISNULL(LA.[CompFuelShutoffPn], '') AS COMP_FUEL_SHUTOFF_PN,
			ISNULL(LA.[CompFuelShutoffSn], '') AS COMP_FUEL_SHUTOFF_SN,
			ISNULL(LA.[CompFuelShutoffInterval], '') AS COMP_FUEL_SHUTOFF_INTERVAL,
			ISNULL(LA.[CompFuelShutoffLast], '') AS COMP_FUEL_SHUTOFF_LAST,
			ISNULL(LA.[CompFuelShutoffNext], '') AS COMP_FUEL_SHUTOFF_NEXT,
			ISNULL(LA.[CompFuelShutoffRemaining], '') AS COMP_FUEL_SHUTOFF_REMAINING,
			ISNULL(LA.[CompFcuPn], '') AS COMP_FCU_PN,
			ISNULL(LA.[CompFcuSn], '') AS COMP_FCU_SN,
			ISNULL(LA.[CompFcuLast], '') AS COMP_FCU_LAST,
			ISNULL(LA.[CompFcuNext], '') AS COMP_FCU_NEXT,
			ISNULL(LA.[CompFcuRemaining], '') AS COMP_FCU_REMAINING,
			ISNULL(LA.[CompFuelPumpPn], '') AS COMP_FUEL_PUMP_PN,
			ISNULL(LA.[CompFuelPumpSn], '') AS COMP_FUEL_PUMP_SN,
			ISNULL(LA.[CompFuelPumpLast], '') AS COMP_FUEL_PUMP_LAST,
			ISNULL(LA.[CompFuelPumpNext], '') AS COMP_FUEL_PUMP_NEXT,
			ISNULL(LA.[CompFuelPumpRemaining], '') AS COMP_FUEL_PUMP_REMAINING,
			ISNULL(LA.[CompTtlBypassPn], '') AS COMP_TTL_BYPASS_PN,
			ISNULL(LA.[CompTtlBypassSn], '') AS COMP_TTL_BYPASS_SN,
			ISNULL(LA.[CompTtlBypassLast], '') AS COMP_TTL_BYPASS_LAST,
			ISNULL(LA.[CompTtlBypassNext], '') AS COMP_TTL_BYPASS_NEXT,
			ISNULL(LA.[CompTtlBypassRemaining], '') AS COMP_TTL_BYPASS_REMAINING,
			ISNULL(LA.[CompPitchControlPn], '') AS COMP_PITCH_CONTROL_PN,
			ISNULL(LA.[CompPitchControlSn], '') AS COMP_PITCH_CONTROL_SN,
			ISNULL(LA.[CompPitchControlLast], '') AS COMP_PITCH_CONTROL_LAST,
			ISNULL(LA.[CompPitchControlNext], '') AS COMP_PITCH_CONTROL_NEXT,
			ISNULL(LA.[CompPitchControlRemaining], '') AS COMP_PITCH_CONTROL_REMAINING,
			ISNULL(LA.[CompPropGovernorPn], '') AS COMP_PROP_GOVERNOR_PN,
			ISNULL(LA.[CompPropGovernorSn], '') AS COMP_PROP_GOVERNOR_SN,
			ISNULL(LA.[CompPropGovernorLast], '') AS COMP_PROP_GOVERNOR_LAST,
			ISNULL(LA.[CompPropGovernorNext], '') AS COMP_PROP_GOVERNOR_NEXT,
			ISNULL(LA.[CompPropGovernorRemaining], '') AS COMP_PROP_GOVERNOR_REMAINING,
			ISNULL(LA.[CompFuelOilHeaterPn], '') AS COMP_FUEL_OIL_HEATER_PN,
			ISNULL(LA.[CompFuelOilHeaterSn], '') AS COMP_FUEL_OIL_HEATER_SN,
			ISNULL(LA.[CompFuelOilHeaterLast], '') AS COMP_FUEL_OIL_HEATER_LAST,
			ISNULL(LA.[CompFuelOilHeaterNext], '') AS COMP_FUEL_OIL_HEATER_NEXT,
			ISNULL(LA.[CompFuelOilHeaterRemaining], '') AS COMP_FUEL_OIL_HEATER_REMAINING,
			ISNULL(LA.[CompInletSensorPn], '') AS COMP_INLET_SENSOR_PN,
			ISNULL(LA.[CompInletSensorSn], '') AS COMP_INLET_SENSOR_SN,
			ISNULL(LA.[CompInletSensorLast], '') AS COMP_INLET_SENSOR_LAST,
			ISNULL(LA.[CompInletSensorNext], '') AS COMP_INLET_SENSOR_NEXT,
			ISNULL(LA.[CompInletSensorRemaining], '') AS COMP_INLET_SENSOR_REMAINING,
			ISNULL(LA.[CompIgnitorBoxPn], '') AS COMP_IGNITOR_BOX_PN,
			ISNULL(LA.[CompIgnitorBoxSn], '') AS COMP_IGNITOR_BOX_SN,
			ISNULL(LA.[CompIgnitorBoxLast], '') AS COMP_IGNITOR_BOX_LAST,
			ISNULL(LA.[CompIgnitorBoxNext], '') AS COMP_IGNITOR_BOX_NEXT,
			ISNULL(LA.[CompIgnitorBoxRemaining], '') AS COMP_IGNITOR_BOX_REMAINING,
			ISNULL(LA.[CompFlowDividerPn], '') AS COMP_FLOW_DIVIDER_PN,
			ISNULL(LA.[CompFlowDividerSn], '') AS COMP_FLOW_DIVIDER_SN,
			ISNULL(LA.[CompFlowDividerLast], '') AS COMP_FLOW_DIVIDER_LAST,
			ISNULL(LA.[CompFlowDividerNext], '') AS COMP_FLOW_DIVIDER_NEXT,
			ISNULL(LA.[CompFlowDividerRemaining], '') AS COMP_FLOW_DIVIDER_REMAINING,
			ISNULL(LA.[CompOilVentValvePn], '') AS COMP_OIL_VENT_VALVE_PN,
			ISNULL(LA.[CompOilVentValveSn], '') AS COMP_OIL_VENT_VALVE_SN,
			ISNULL(LA.[CompOilVentValveInterval], '') AS COMP_OIL_VENT_VALVE_INTERVAL,
			ISNULL(LA.[CompOilVentValveLast], '') AS COMP_OIL_VENT_VALVE_LAST,
			ISNULL(LA.[CompOilVentValveNext], '') AS COMP_OIL_VENT_VALVE_NEXT,
			ISNULL(LA.[CompOilVentValveRemaining], '') AS COMP_OIL_VENT_VALVE_REMAINING,
			ISNULL(LA.[CompAutoIgnitionPn], '') AS COMP_AUTO_IGNITION_PN,
			ISNULL(LA.[CompAutoIgnitionSn], '') AS COMP_AUTO_IGNITION_SN,
			ISNULL(LA.[CompStartPressRegPn], '') AS COMP_START_PRESS_REG_PN,
			ISNULL(LA.[CompStartPressRegSn], '') AS COMP_START_PRESS_REG_SN,
			ISNULL(LA.[IncidentEngineTotalTime], '') AS INCIDENT_ENGINE_TOTAL_TIME,
			ISNULL(LA.[IncidentEngineTotalCycles], '') AS INCIDENT_ENGINE_TOTAL_CYCLES,
			ISNULL(LA.[IncidentAircraftTotalTime], '') AS INCIDENT_AIRCRAFT_TOTAL_TIME,
			ISNULL(LA.[IncidentAircraftTotalCycles], '') AS INCIDENT_AIRCRAFT_TOTAL_CYCLES,
			CASE WHEN LA.[IncidentDate] IS NULL THEN '' ELSE CONVERT(VARCHAR(10), LA.[IncidentDate], 101) END AS INCIDENT_DATE,
			ISNULL(LA.[IncidentTime], '') AS INCIDENT_TIME,
			ISNULL(LA.[IncidentLocation], '') AS INCIDENT_LOCATION,
			ISNULL(LA.[IncidentPhaseOfFlight], '') AS INCIDENT_PHASE_OF_FLIGHT,
			ISNULL(LA.[IncidentDescription], '') AS INCIDENT_DESCRIPTION,
			ISNULL(LA.[DamageDescription], '') AS DAMAGE_DESCRIPTION,
			ISNULL(LA.[FlightCrewObservations], '') AS FLIGHT_CREW_OBSERVATIONS,
			ISNULL(LA.[InsuranceCompany], '') AS INSURANCE_COMPANY,
			ISNULL(LA.[InsuranceContactName], '') AS INSURANCE_CONTACT_NAME,
			ISNULL(LA.[InsuranceContactPhone], '') AS INSURANCE_CONTACT_PHONE,
			ISNULL(LA.[InsuranceContactEmail], '') AS INSURANCE_CONTACT_EMAIL,
			CASE WHEN LA.[InsuranceDeductibleAmount] IS NULL THEN '' ELSE FORMAT(LA.[InsuranceDeductibleAmount], 'N2') END AS INSURANCE_DEDUCTIBLE_AMOUNT
		FROM [dbo].[LeaseAgreement] LA WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LA.[LeaseHeaderId]
		WHERE LA.[LeaseAgreementId] = @LeaseAgreementId
		  AND LA.[IsDeleted] = 0;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeaseAgreementPDFData]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseAgreementId = ''' + CAST(ISNULL(@LeaseAgreementId, 0) AS VARCHAR(100)),
			@ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName,
							@AdhocComments = @AdhocComments,
							@ProcedureParameters = @ProcedureParameters,
							@ApplicationName = @ApplicationName,
							@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END

