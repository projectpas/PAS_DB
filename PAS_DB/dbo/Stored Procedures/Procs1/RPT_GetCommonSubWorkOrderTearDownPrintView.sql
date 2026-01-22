/*************************************************************           
 ** File:   [RPT_GetCommonSubWorkOrderTearDownPrintView]           
 ** Author: AMIT GHEDIYA
 ** Description: This stored procedure is used GetCommonSubWorkOrderTearDownPrintView
 ** Purpose:         
 ** Date:   29/12/2023

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    29/12/2023   AMIT GHEDIYA			Created
     
--EXEC [RPT_GetCommonSubWorkOrderTearDownPrintView] 18, 134
**************************************************************/
CREATE   PROCEDURE [dbo].[RPT_GetCommonSubWorkOrderTearDownPrintView]
	@SubWorkorderId BIGINT = 0,
	@WorkorderId BIGINT = 0,
	@SubWOPartNoId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @ItemMasterIdlist VARCHAR(max) = '0';

				SELECT @ItemMasterIdlist = TearDownTypes FROM DBO.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkorderId;

			    SELECT DISTINCT tdt.CommonTearDownTypeId,
					ISNULL(td.ReasonName,'') ReasonName,
                    ISNULL(td.TechnicalName,'') AS Technician,
                    ISNULL(td.InspectorName,'') AS Inspector,
                    --ISNULL(td.Memo,'') AS Memo,
					REPLACE(REPLACE(ISNULL(td.Memo,''), '<p>', ''),'</p>','<br />') as Memo,
                    td.TechnicianDate AS TechnicianDate,
                    td.InspectorDate AS InspectorDate,
                    td.IsDocument AS IsDocumentAdded,
					tdt.[Name] AS TearDownType,
					tdt.IsTechnician,
					tdt.[IsDate],
					tdt.IsInspector,
					tdt.IsInspectorDate,
					tdt.IsDocument,
					tdt.[Sequence],
					tdt.DocumentModuleName
				FROM [dbo].[CommonTeardownType] tdt WITH(NOLOCK)
				LEFT JOIN [dbo].[CommonWorkOrderTearDown] td WITH(NOLOCK) ON td.CommonTearDownTypeId = tdt.CommonTearDownTypeId
				AND td.SubWorkOrderId = @SubWorkorderId AND td.IsSubWorkOrder = 1 AND td.SubWOPartNoId = @SubWOPartNoId
				WHERE tdt.CommonTearDownTypeId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIdlist,','))
				ORDER BY tdt.[Sequence]
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCommonSubWorkOrderTearDownPrintView' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkorderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END