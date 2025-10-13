/*************************************************************           
 ** File:   [USP_GetEmployeeViewDetailsList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get EmployeeViewDetails List
 ** Purpose:         
 ** Date:   28-07-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    28-07-2025    Sahdev Saliya       Created  

	exec [USP_GetEmployeeViewDetailsList] 243
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetEmployeeViewDetailsList]
    @EmployeeId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#Results') IS NOT NULL
		DROP TABLE #Results

	IF OBJECT_ID('tempdb..#tmpEmployeeTraining') IS NOT NULL
		DROP TABLE #tmpEmployeeTraining

	IF OBJECT_ID('tempdb..#tmpEmployeeCertification') IS NOT NULL
		DROP TABLE #tmpEmployeeCertification

	IF OBJECT_ID('tempdb..#tmpEmployeeCertificationtype') IS NOT NULL
		DROP TABLE #tmpEmployeeCertificationtype

	IF OBJECT_ID('tempdb..#tmpEmployeeLeaveTypeMapping') IS NOT NULL
		DROP TABLE #tmpEmployeeLeaveTypeMapping

	IF OBJECT_ID('tempdb..#tmpEmployeeShiftMapping') IS NOT NULL
		DROP TABLE #tmpEmployeeShiftMapping

	 DECLARE @ModuleId BIGINT = (SELECT ManagementStructureModuleId FROM [dbo].ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'EmployeeGeneralInfo');
	 DECLARE @ReferenceName VARCHAR(100) = '';
	 DECLARE @TrainingType VARCHAR(256) = '';

	 BEGIN TRY

		SELECT 
		    e.EmployeeId,
			e.FirstName,
			e.LastName,
			e.MiddleName,
			e.EmployeeIdAsPerPayroll,
			e.StationId,
			e.JobTitleId,
			e.LegalEntityId,
			e.DateOfBirth,
			e.StartDate,
			e.EmployeeCode,
			e.MobilePhone,
			e.WorkPhone,
			e.Fax,
			e.Email,
			e.SSN,
			e.InMultipleShifts,
			e.AllowOvertime,
			e.AllowDoubleTime,
			e.IsHourly,
			e.HourlyPay,
			e.EmployeeCertifyingStaff,
			e.SupervisorId,
			e.MasterCompanyId,
			e.IsDeleted,
			e.ManagementStructureId,
			'' AS LeaveTypeIds,
			'' AS ShiftIds,
			e.IsActive,
			e.CreatedDate,
			e.CreatedBy,
			e.UpdatedBy,
			e.UpdatedDate,
			e.CurrencyId,
		    e.TwoFactorAuthentication,
			ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
			ISNULL(msd.AllMSlevels, '') AS AllMSlevels,
			ISNULL(CONVERT(VARCHAR, ee.IsWorksInShop), '') AS IsHeWorksInShop,
			ISNULL(e.Memo, '') AS Memo,
			ISNULL(anu.NormalizedUserName, '') AS UserName,
			e.MRORevenuePercentageId,
			e.BrokeringRevenuePercentageId,
			e.ManufacturingRevenuePercentageId,
			e.MROMarginPercentageId,
			e.BrokeringMarginPercentageId,
			e.ManufacturingMarginPercentageId
		INTO #Results
		FROM [dbo].Employee e WITH(NOLOCK)
		LEFT JOIN [dbo].EmployeeManagementStructureDetails msd WITH(NOLOCK) ON e.EmployeeId = msd.ReferenceID AND msd.ModuleID = @ModuleId
		LEFT JOIN [dbo].EmployeeExpertise ee WITH(NOLOCK) ON e.EmployeeExpertiseId = ee.EmployeeExpertiseId
		LEFT JOIN [dbo].AspNetUsers anu WITH(NOLOCK) ON e.EmployeeId = anu.EmployeeId
		 WHERE e.EmployeeId = @EmployeeId

		SELECT 
			et.EmployeeTrainingId,
			et.EmployeeId,
			et.AircraftManufacturerId,
			et.AircraftModelId,
			null AS AircraftModelIds,
			et.Provider,
			et.IndustryCode,
			et.EmployeeTrainingTypeId,
			et.FrequencyOfTrainingId,
			et.Cost,
			et.Duration,
			et.DurationTypeId,
			et.ScheduleDate,
			et.CompletionDate,
			et.ExpirationDate,
			@ReferenceName AS AircraftModelName,
			@ReferenceName AS AircraftManufacturerName,
			@TrainingType AS EmployeeTrainingTypeName,
			@ReferenceName AS FrequencyOfTrainingName,
			et.InternalReference,
			et.Memo,
			'' AS AircraftModelsIds,
			et.MasterCompanyId,
			et.CreatedBy,
			et.CreatedDate,
			et.UpdatedBy,
			et.UpdatedDate,
			et.IsActive,
			et.IsDeleted
		INTO #tmpEmployeeTraining
		FROM [dbo].EmployeeTraining et WITH(NOLOCK)
		 WHERE et.EmployeeId = @EmployeeId

		 SELECT 
			ec.EmployeeCertificationId,
			ec.EmployeeId,
			ec.CertificationNumber,
			ec.EmployeeCertificationTypeId,
			ec.CertifyingInstitution,
			ec.CertificationDate,
			ec.IsCertificationInForce,
			ec.ExpirationDate,
			ec.IsExpirationDate,
			ec.Memo,
			'' AS CertType,
			'' AS Inforce,
			ec.MasterCompanyId,
			ec.CreatedBy,
			ec.CreatedDate,
			ec.UpdatedBy,
			ec.UpdatedDate,
			ec.IsActive,
			ec.IsDeleted
		INTO #tmpEmployeeCertification
		FROM [dbo].EmployeeCertification ec WITH(NOLOCK)
		 WHERE ec.EmployeeId = @EmployeeId

		 SELECT 
			ect.EmployeeCertificationTypeId,
			ect.Description,
			ect.Memo,
			ect.MasterCompanyId,
			ect.CreatedBy,
			ect.CreatedDate,
			ect.UpdatedBy,
			ect.UpdatedDate,
			ect.IsActive,
			ect.IsDeleted
		INTO #tmpEmployeeCertificationtype
		FROM [dbo].EmployeeCertificationType ect WITH(NOLOCK)
		INNER JOIN [dbo].EmployeeCertification ec WITH(NOLOCK) ON ect.EmployeeCertificationTypeId = ec.EmployeeCertificationTypeId
		 WHERE ec.EmployeeId = @EmployeeId

		 SELECT 
			eltm.EmployeeLeaveTypeMappingId,
			eltm.EmployeeId,
			eltm.EmployeeLeaveTypeId,
			eltm.MasterCompanyId,
			eltm.CreatedBy,
			eltm.CreatedDate,
			eltm.UpdatedBy,
			eltm.UpdatedDate,
			eltm.IsActive,
			eltm.IsDeleted
		INTO #tmpEmployeeLeaveTypeMapping
		FROM [dbo].EmployeeLeaveTypeMapping eltm WITH(NOLOCK)
		 WHERE eltm.EmployeeId = @EmployeeId

		 SELECT 
			esm.EmployeeShiftMappingId,
			esm.EmployeeId,
			esm.ShiftId,
			esm.MasterCompanyId,
			esm.CreatedBy,
			esm.CreatedDate,
			esm.UpdatedBy,
			esm.UpdatedDate,
			esm.IsActive,
			esm.IsDeleted
		INTO #tmpEmployeeShiftMapping
		FROM [dbo].EmployeeShiftMapping esm
		 WHERE esm.EmployeeId = @EmployeeId

		IF EXISTS(SELECT 1 FROM #Results)
		BEGIN
			IF EXISTS(SELECT 1 FROM #tmpEmployeeTraining)
			BEGIN
				UPDATE TMP
				SET	TMP.AircraftModelName = ISNULL(ACM.ModelName, ''),
					TMP.AircraftManufacturerName = ISNULL(ACT.Description, ''),
					TMP.EmployeeTrainingTypeName = ISNULL(ETT.TrainingType, ''),
					TMP.FrequencyOfTrainingName = ISNULL(FOT.FrequencyName, '')
				FROM #tmpEmployeeTraining TMP
				LEFT JOIN [dbo].AircraftModel ACM WITH(NOLOCK) ON ACM.AircraftModelId = TMP.AircraftModelId
				LEFT JOIN [dbo].AircraftType ACT WITH(NOLOCK) ON ACT.AircraftTypeId = TMP.AircraftManufacturerId
				LEFT JOIN [dbo].EmployeeTrainingType ETT WITH(NOLOCK) ON ETT.EmployeeTrainingTypeId = TMP.EmployeeTrainingTypeId 
				LEFT JOIN [dbo].FrequencyOfTraining FOT WITH(NOLOCK) ON FOT.FrequencyOfTrainingId = TMP.FrequencyOfTrainingId 
			END
		END

		SELECT * FROM #Results
		SELECT * FROM #tmpEmployeeTraining
		SELECT * FROM #tmpEmployeeCertification
		SELECT * FROM #tmpEmployeeCertificationtype
		SELECT * FROM #tmpEmployeeLeaveTypeMapping
		SELECT * FROM #tmpEmployeeShiftMapping

    END TRY

   BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetEmployeeViewDetailsList' 
				  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') as varchar(100))   
				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END