
CREATE PROCEDURE [dbo].[GetWorkFlowAuditList]
@wfwoId BIGINT = null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
	  BEGIN TRY
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
                wof.CreatedDate,
                wof.IsActive,
                wof.IsDeleted,
                wof.MasterCompanyId,
                wof.UpdatedBy,
                wof.UpdatedDate,
                CostOfReplacement,
                PercentageOfReplacement,
                Memo,
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
				Currency
			FROM [dbo].[WorkflowAudit] wof WITH(NOLOCK)				
			WHERE wof.WorkflowId = @wfwoId or wof.WFParentId = @wfwoId
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