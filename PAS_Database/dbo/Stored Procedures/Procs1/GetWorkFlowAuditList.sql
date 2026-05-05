/***************************************************************  
 ** File:   [GetWorkFlowAuditList]            
 ** Author:   
 ** Description: This stored procedure is used to [GetWorkFlowAuditList]
 ** Date:  
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  					Change Description              
 ** --   --------			-------					--------------------------------            
	2    20-March-2025      Ekta Chandegra          Convert date using dbo.ConvertUTCtoLocal
	3    05-May-2026        Priyansh Patel          Added Aircraft related fields [PN-16276]

	exec dbo.GetWorkFlowAuditList @wfwoId=5200,@EmployeeId=223

**************************************************************/
CREATE PROCEDURE [dbo].[GetWorkFlowAuditList]
@wfwoId BIGINT = null,
@EmployeeId BIGINT
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
	  BEGIN TRY

	  DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

				SELECT 
						@CurrntEmpTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM 
						dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN 
						dbo.TimeZone ETZ WITH (NOLOCK) 
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN 
						dbo.LegalEntity LE WITH (NOLOCK) 
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN 
						dbo.TimeZone LTZ WITH (NOLOCK) 
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE 
						E.EmployeeId = @EmployeeId;
			SELECT	
				WorkflowId,
                WorkflowDescription,
                Version,
                PartNumberDescription,
                WorkflowExpirationDate,
                FixedAmount,
                CostOfNew,
                PercentageOfNew,
                wof.CreatedBy,
				(Cast(DBO.ConvertUTCtoLocal(wof.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) CreatedDate,
                wof.IsActive,
                wof.IsDeleted,
                wof.MasterCompanyId,
                wof.UpdatedBy,
				(Cast(DBO.ConvertUTCtoLocal(wof.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) UpdatedDate,
                CostOfReplacement,
                PercentageOfReplacement,
                wof.Memo,
				PartNumber,
				CustomerName,
				FlatRate,
				BERThresholdAmount,
				wof.WorkOrderNumber,
                wof.CustomerCode,
                wof.OtherCost,
                wof.WorkflowCreateDate,
                wof.PercentageOfTotal,
                wof.RevisedPartNumber,
                changedPartNumberDescription,
                ChangedPartNumber,
                WorkScope,
				Currency,
                wof.TailNum,
                wof.SerialNum,
                wof.AircraftModelId,
                wof.MakeTypeId,
                wof.TemplateType,
                wof.MaintenanceTypeId,
                ACM.ModelName       AS AircraftModel,
                ACT.[Description]   AS AircraftMake,
                MT.[Description]    AS MaintenanceType
			FROM [dbo].[WorkflowAudit] wof WITH(NOLOCK)	
			LEFT JOIN [dbo].[AircraftModel]   ACM WITH(NOLOCK) ON ACM.AircraftModelId  = wof.AircraftModelId
            LEFT JOIN [dbo].[AircraftType]    ACT WITH(NOLOCK) ON ACT.AircraftTypeId   = wof.MakeTypeId
            LEFT JOIN [dbo].[MaintenanceType] MT  WITH(NOLOCK) ON MT.MaintenanceTypeId = wof.MaintenanceTypeId
			WHERE wof.WorkflowId = @wfwoId or wof.WFParentId = @wfwoId
			ORDER BY wof.WorkflowId DESC
	  END TRY 
	  BEGIN CATCH   	
			  
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkFlowAuditList'               
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@wfwoId, '') as varchar(100))
													
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH			           
END