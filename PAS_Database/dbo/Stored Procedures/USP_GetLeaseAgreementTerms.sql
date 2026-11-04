/*************************************************************
 ** File:   [USP_GetLeaseAgreementTerms]
 ** Description: Lease terms (the editable values of the agreement) to show in the Lease Agreement popup.
 **              Returns ONE row for the lease stockline:
 **                Source = 'LEASE'   -> the saved agreement of THIS lease stockline (values as saved, blank stays blank)
 **                Source = 'COMPANY' -> no agreement yet: the values that belong to the company (lessor entity, payment /
 **                                      wire instructions, locations, governing law, ...) are taken from the last agreement
 **                                      of the company, the lease specific values are NULL (the screen puts its defaults)
 **                Source = 'NEW'     -> nothing saved yet in the company: all terms are NULL (the screen puts its defaults)
 **              AgreementDueDate falls back to LeaseStockline.EndDate. The defaults themselves (values of the sample
 **              agreement) are in the screen, not in the database.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    02/11/2026     Rajesh Gami             [PN-18468] Created - Lease terms of the Lease Agreement

exec USP_GetLeaseAgreementTerms @LeaseHeaderId=1, @LeaseStocklineId=1, @MasterCompanyId=1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseAgreementTerms]
	@LeaseHeaderId BIGINT,
	@LeaseStocklineId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @LeaseAgreementId BIGINT = NULL, @CompanyAgreementId BIGINT = NULL;

		-- saved agreement of this lease stockline (LeaseHeaderId + LeaseStocklineId + MasterCompanyId)
		SELECT TOP 1 @LeaseAgreementId = LA.[LeaseAgreementId]
		FROM [dbo].[LeaseAgreement] LA WITH (NOLOCK)
		WHERE LA.[LeaseHeaderId]    = @LeaseHeaderId
		  AND LA.[LeaseStocklineId] = @LeaseStocklineId
		  AND LA.[MasterCompanyId]  = @MasterCompanyId
		  AND LA.[IsDeleted] = 0
		ORDER BY LA.[VersionNo] DESC, LA.[LeaseAgreementId] DESC;

		-- no version yet: last agreement of the company (only its company level terms are used)
		IF (@LeaseAgreementId IS NULL)
		BEGIN
			SELECT TOP 1 @CompanyAgreementId = LA.[LeaseAgreementId]
			FROM [dbo].[LeaseAgreement] LA WITH (NOLOCK)
			WHERE LA.[MasterCompanyId] = @MasterCompanyId
			  AND LA.[IsDeleted] = 0
			ORDER BY LA.[LeaseAgreementId] DESC;
		END

		SELECT
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN 'LEASE'
				 WHEN @CompanyAgreementId IS NOT NULL THEN 'COMPANY'
				 ELSE 'NEW' END                                     AS [Source],
			ISNULL(CUR.[VersionNo], 0)                              AS [VersionNo],
			CUR.[AgreementDate]                                     AS [AgreementDate],
			ISNULL(CUR.[AgreementDueDate], LSL.[EndDate])           AS [AgreementDueDate],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[LessorEntityJurisdictionType] ELSE CO.[LessorEntityJurisdictionType] END AS [LessorEntityJurisdictionType],
			CUR.[LesseeEntityJurisdictionType] AS [LesseeEntityJurisdictionType],
			CUR.[LeasePurpose] AS [LeasePurpose],
			CUR.[EngineTsn] AS [EngineTsn],
			CUR.[EngineCsn] AS [EngineCsn],
			CUR.[InsuredValue] AS [InsuredValue],
			CUR.[AircraftManufacturer] AS [AircraftManufacturer],
			CUR.[AircraftTypeModel] AS [AircraftTypeModel],
			CUR.[AircraftRegistration] AS [AircraftRegistration],
			CUR.[AircraftSerialNumber] AS [AircraftSerialNumber],
			CUR.[ExtensionOptions] AS [ExtensionOptions],
			CUR.[ExtensionNoticeDays] AS [ExtensionNoticeDays],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[ReturnShippingLocation] ELSE CO.[ReturnShippingLocation] END AS [ReturnShippingLocation],
			CUR.[ReturnDeliveryDays] AS [ReturnDeliveryDays],
			CUR.[SecurityDepositAmount] AS [SecurityDepositAmount],
			CUR.[FlightHourRate] AS [FlightHourRate],
			CUR.[CycleRate] AS [CycleRate],
			CUR.[LeaseInceptionFee] AS [LeaseInceptionFee],
			CUR.[LeaseInceptionFeeStatus] AS [LeaseInceptionFeeStatus],
			CUR.[LeaseReturnFee] AS [LeaseReturnFee],
			CUR.[DefaultDailyRate] AS [DefaultDailyRate],
			CUR.[DefaultHourlyRate] AS [DefaultHourlyRate],
			CUR.[DefaultCycleRate] AS [DefaultCycleRate],
			CUR.[LateReturnGraceDays] AS [LateReturnGraceDays],
			CUR.[LateReturnDailyCharge] AS [LateReturnDailyCharge],
			CUR.[UsageReportingDay] AS [UsageReportingDay],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[PaymentDueRule] ELSE CO.[PaymentDueRule] END AS [PaymentDueRule],
			CUR.[LateFeeGraceDays] AS [LateFeeGraceDays],
			CUR.[LatePaymentFee] AS [LatePaymentFee],
			CUR.[InterestTriggerDays] AS [InterestTriggerDays],
			CUR.[MonthlyInterestRate] AS [MonthlyInterestRate],
			CUR.[CollectionTriggerDays] AS [CollectionTriggerDays],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[PaymentMailingInstructions] ELSE CO.[PaymentMailingInstructions] END AS [PaymentMailingInstructions],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[PaymentWireInstructions] ELSE CO.[PaymentWireInstructions] END AS [PaymentWireInstructions],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[DeliveryLocation] ELSE CO.[DeliveryLocation] END AS [DeliveryLocation],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[ReturnLocation] ELSE CO.[ReturnLocation] END AS [ReturnLocation],
			CUR.[ReturnTransitDays] AS [ReturnTransitDays],
			CUR.[FuelFilterCapCharge] AS [FuelFilterCapCharge],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[ApprovedOilAnalysisKit] ELSE CO.[ApprovedOilAnalysisKit] END AS [ApprovedOilAnalysisKit],
			CUR.[ReturnInspectionRequirement] AS [ReturnInspectionRequirement],
			CUR.[ReturnInspectionRatePerHour] AS [ReturnInspectionRatePerHour],
			CUR.[ReturnInspectionMaxCharge] AS [ReturnInspectionMaxCharge],
			CUR.[MissingDataSheetCharge] AS [MissingDataSheetCharge],
			CUR.[SecurityDepositRefundDays] AS [SecurityDepositRefundDays],
			CUR.[SoapTriggerHours] AS [SoapTriggerHours],
			CUR.[SoapCompletionHoursAfterRemoval] AS [SoapCompletionHoursAfterRemoval],
			CUR.[SoapMissingReportCharge] AS [SoapMissingReportCharge],
			CUR.[DefaultCureDays] AS [DefaultCureDays],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[NoticeDeliveryMethod] ELSE CO.[NoticeDeliveryMethod] END AS [NoticeDeliveryMethod],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[GoverningLawState] ELSE CO.[GoverningLawState] END AS [GoverningLawState],
			CUR.[LesseeSignatoryTitle] AS [LesseeSignatoryTitle],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[LessorSignatoryName] ELSE CO.[LessorSignatoryName] END AS [LessorSignatoryName],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[LessorSignatoryTitle] ELSE CO.[LessorSignatoryTitle] END AS [LessorSignatoryTitle],
			CUR.[LesseeSignatureDate] AS [LesseeSignatureDate],
			CUR.[LessorSignatureDate] AS [LessorSignatureDate],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[LessorFax] ELSE CO.[LessorFax] END AS [LessorFax],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[MinimumAircraftLiabilityCoverage] ELSE CO.[MinimumAircraftLiabilityCoverage] END AS [MinimumAircraftLiabilityCoverage],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[InsuranceCertificateHolder] ELSE CO.[InsuranceCertificateHolder] END AS [InsuranceCertificateHolder],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[CancellationNoticeDays] ELSE CO.[CancellationNoticeDays] END AS [CancellationNoticeDays],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[NonpaymentCancellationNoticeDays] ELSE CO.[NonpaymentCancellationNoticeDays] END AS [NonpaymentCancellationNoticeDays],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[IncidentReportHours] ELSE CO.[IncidentReportHours] END AS [IncidentReportHours],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[BetaSwitchSupplyStatus] ELSE CO.[BetaSwitchSupplyStatus] END AS [BetaSwitchSupplyStatus],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[NtsSwitchSupplyStatus] ELSE CO.[NtsSwitchSupplyStatus] END AS [NtsSwitchSupplyStatus],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[TempCompensatorSupplyStatus] ELSE CO.[TempCompensatorSupplyStatus] END AS [TempCompensatorSupplyStatus],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[CompFlowDividerInterval] ELSE CO.[CompFlowDividerInterval] END AS [CompFlowDividerInterval],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[LessorLegalName] ELSE CO.[LessorLegalName] END AS [LessorLegalName],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[LessorAddress] ELSE CO.[LessorAddress] END AS [LessorAddress],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[LessorPhone] ELSE CO.[LessorPhone] END AS [LessorPhone],
			CASE WHEN @LeaseAgreementId IS NOT NULL THEN CUR.[LessorNoticeEmail] ELSE CO.[LessorNoticeEmail] END AS [LessorNoticeEmail],
			CUR.[LesseeLegalName] AS [LesseeLegalName],
			CUR.[LesseeAddress] AS [LesseeAddress],
			CUR.[LesseeNoticeEmail] AS [LesseeNoticeEmail],
			CUR.[LesseeSignatoryName] AS [LesseeSignatoryName],
			CUR.[PurchaseOrderNumber] AS [PurchaseOrderNumber],
			CUR.[EngineManufacturer] AS [EngineManufacturer],
			CUR.[EngineModelNumber] AS [EngineModelNumber],
			CUR.[EngineSerialNumber] AS [EngineSerialNumber],
			CUR.[Currency] AS [Currency],
			CUR.[PaymentCurrency] AS [PaymentCurrency],
			CUR.[MonthlyRentAmount] AS [MonthlyRentAmount],
			CUR.[PreRemovalStatusDate] AS [PreRemovalStatusDate],
			CUR.[PressureAltitude] AS [PressureAltitude],
			CUR.[Oat] AS [Oat],
			CUR.[EgtCompensatorSetting] AS [EgtCompensatorSetting],
			CUR.[BleedAirValve] AS [BleedAirValve],
			CUR.[TargetTorque] AS [TargetTorque],
			CUR.[ActualTorque] AS [ActualTorque],
			CUR.[TargetTemperature] AS [TargetTemperature],
			CUR.[ActualTemperature] AS [ActualTemperature],
			CUR.[TargetFuelFlow] AS [TargetFuelFlow],
			CUR.[ActualFuelFlow] AS [ActualFuelFlow],
			CUR.[CompFuelShutoffPn] AS [CompFuelShutoffPn],
			CUR.[CompFuelShutoffSn] AS [CompFuelShutoffSn],
			CUR.[CompFuelShutoffInterval] AS [CompFuelShutoffInterval],
			CUR.[CompFuelShutoffLast] AS [CompFuelShutoffLast],
			CUR.[CompFuelShutoffNext] AS [CompFuelShutoffNext],
			CUR.[CompFuelShutoffRemaining] AS [CompFuelShutoffRemaining],
			CUR.[CompFcuPn] AS [CompFcuPn],
			CUR.[CompFcuSn] AS [CompFcuSn],
			CUR.[CompFcuLast] AS [CompFcuLast],
			CUR.[CompFcuNext] AS [CompFcuNext],
			CUR.[CompFcuRemaining] AS [CompFcuRemaining],
			CUR.[CompFuelPumpPn] AS [CompFuelPumpPn],
			CUR.[CompFuelPumpSn] AS [CompFuelPumpSn],
			CUR.[CompFuelPumpLast] AS [CompFuelPumpLast],
			CUR.[CompFuelPumpNext] AS [CompFuelPumpNext],
			CUR.[CompFuelPumpRemaining] AS [CompFuelPumpRemaining],
			CUR.[CompTtlBypassPn] AS [CompTtlBypassPn],
			CUR.[CompTtlBypassSn] AS [CompTtlBypassSn],
			CUR.[CompTtlBypassLast] AS [CompTtlBypassLast],
			CUR.[CompTtlBypassNext] AS [CompTtlBypassNext],
			CUR.[CompTtlBypassRemaining] AS [CompTtlBypassRemaining],
			CUR.[CompPitchControlPn] AS [CompPitchControlPn],
			CUR.[CompPitchControlSn] AS [CompPitchControlSn],
			CUR.[CompPitchControlLast] AS [CompPitchControlLast],
			CUR.[CompPitchControlNext] AS [CompPitchControlNext],
			CUR.[CompPitchControlRemaining] AS [CompPitchControlRemaining],
			CUR.[CompPropGovernorPn] AS [CompPropGovernorPn],
			CUR.[CompPropGovernorSn] AS [CompPropGovernorSn],
			CUR.[CompPropGovernorLast] AS [CompPropGovernorLast],
			CUR.[CompPropGovernorNext] AS [CompPropGovernorNext],
			CUR.[CompPropGovernorRemaining] AS [CompPropGovernorRemaining],
			CUR.[CompFuelOilHeaterPn] AS [CompFuelOilHeaterPn],
			CUR.[CompFuelOilHeaterSn] AS [CompFuelOilHeaterSn],
			CUR.[CompFuelOilHeaterLast] AS [CompFuelOilHeaterLast],
			CUR.[CompFuelOilHeaterNext] AS [CompFuelOilHeaterNext],
			CUR.[CompFuelOilHeaterRemaining] AS [CompFuelOilHeaterRemaining],
			CUR.[CompInletSensorPn] AS [CompInletSensorPn],
			CUR.[CompInletSensorSn] AS [CompInletSensorSn],
			CUR.[CompInletSensorLast] AS [CompInletSensorLast],
			CUR.[CompInletSensorNext] AS [CompInletSensorNext],
			CUR.[CompInletSensorRemaining] AS [CompInletSensorRemaining],
			CUR.[CompIgnitorBoxPn] AS [CompIgnitorBoxPn],
			CUR.[CompIgnitorBoxSn] AS [CompIgnitorBoxSn],
			CUR.[CompIgnitorBoxLast] AS [CompIgnitorBoxLast],
			CUR.[CompIgnitorBoxNext] AS [CompIgnitorBoxNext],
			CUR.[CompIgnitorBoxRemaining] AS [CompIgnitorBoxRemaining],
			CUR.[CompFlowDividerPn] AS [CompFlowDividerPn],
			CUR.[CompFlowDividerSn] AS [CompFlowDividerSn],
			CUR.[CompFlowDividerLast] AS [CompFlowDividerLast],
			CUR.[CompFlowDividerNext] AS [CompFlowDividerNext],
			CUR.[CompFlowDividerRemaining] AS [CompFlowDividerRemaining],
			CUR.[CompOilVentValvePn] AS [CompOilVentValvePn],
			CUR.[CompOilVentValveSn] AS [CompOilVentValveSn],
			CUR.[CompOilVentValveInterval] AS [CompOilVentValveInterval],
			CUR.[CompOilVentValveLast] AS [CompOilVentValveLast],
			CUR.[CompOilVentValveNext] AS [CompOilVentValveNext],
			CUR.[CompOilVentValveRemaining] AS [CompOilVentValveRemaining],
			CUR.[CompAutoIgnitionPn] AS [CompAutoIgnitionPn],
			CUR.[CompAutoIgnitionSn] AS [CompAutoIgnitionSn],
			CUR.[CompStartPressRegPn] AS [CompStartPressRegPn],
			CUR.[CompStartPressRegSn] AS [CompStartPressRegSn],
			CUR.[IncidentEngineTotalTime] AS [IncidentEngineTotalTime],
			CUR.[IncidentEngineTotalCycles] AS [IncidentEngineTotalCycles],
			CUR.[IncidentAircraftTotalTime] AS [IncidentAircraftTotalTime],
			CUR.[IncidentAircraftTotalCycles] AS [IncidentAircraftTotalCycles],
			CUR.[IncidentDate] AS [IncidentDate],
			CUR.[IncidentTime] AS [IncidentTime],
			CUR.[IncidentLocation] AS [IncidentLocation],
			CUR.[IncidentPhaseOfFlight] AS [IncidentPhaseOfFlight],
			CUR.[IncidentDescription] AS [IncidentDescription],
			CUR.[DamageDescription] AS [DamageDescription],
			CUR.[FlightCrewObservations] AS [FlightCrewObservations],
			CUR.[InsuranceCompany] AS [InsuranceCompany],
			CUR.[InsuranceContactName] AS [InsuranceContactName],
			CUR.[InsuranceContactPhone] AS [InsuranceContactPhone],
			CUR.[InsuranceContactEmail] AS [InsuranceContactEmail],
			CUR.[InsuranceDeductibleAmount] AS [InsuranceDeductibleAmount]
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		 LEFT JOIN [dbo].[LeaseAgreement] CUR WITH (NOLOCK) ON CUR.[LeaseAgreementId] = @LeaseAgreementId
		 LEFT JOIN [dbo].[LeaseAgreement] CO WITH (NOLOCK)  ON CO.[LeaseAgreementId] = @CompanyAgreementId
		WHERE LSL.[LeaseStocklineId] = @LeaseStocklineId
		  AND LSL.[LeaseHeaderId]    = @LeaseHeaderId
		  AND LSL.[IsDeleted]        = 0;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeaseAgreementTerms]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100))
											   + ''', @LeaseStocklineId = ''' + CAST(ISNULL(@LeaseStocklineId, 0) AS VARCHAR(100))
											   + ''', @MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100)),
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
