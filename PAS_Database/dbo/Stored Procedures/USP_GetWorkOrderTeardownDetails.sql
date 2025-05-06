/*************************************************************           
 ** File:   [USP_GetWorkOrderTeardownDetails]           
 ** Author:   Bhargav Saliya 
 ** Description: Get WorkOrder/SWO Teardown Details
 ** Purpose:         
 ** Date:   06-May-2025      
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    06-May-2025   Bhargav Saliya		Created

**************************************************************/
--EXEC [USP_GetWorkOrderTeardownDetails] @IsSubWorkOrder = 0,@WorkOrderId = 8808,@WorkFlowWorkOrderId = 8547,@MasterCompanyId =1,@SubWOPartNoId = 0
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderTeardownDetails]
    @MasterCompanyId BIGINT,
    @WorkOrderId BIGINT,
    @WorkFlowWorkOrderId BIGINT,
    @IsSubWorkOrder BIT,
    @SubWOPartNoId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @TearDownTypes VARCHAR(MAX);
		DECLARE @WorkOrderIdFromSubWorkOrder BIGINT;

		IF @IsSubWorkOrder = 1
		BEGIN
			SELECT @WorkOrderIdFromSubWorkOrder = WorkOrderId
			FROM [dbo].[SubWorkOrder] WITH(NOLOCK) WHERE SubWorkOrderId = @WorkOrderId;

			SELECT @TearDownTypes = TearDownTypes
			FROM [dbo].[WorkOrder] WITH(NOLOCK) 
			WHERE MasterCompanyId = @MasterCompanyId AND WorkOrderId = @WorkOrderIdFromSubWorkOrder
				  AND IsActive = 1 AND IsDeleted = 0;
		END
		ELSE
		BEGIN
			SELECT @TearDownTypes = TearDownTypes
			FROM [dbo].[WorkOrder]
			WHERE MasterCompanyId = @MasterCompanyId AND WorkOrderId = @WorkOrderId AND IsActive = 1 AND IsDeleted = 0;
		END

		IF @TearDownTypes IS NOT NULL AND LEN(@TearDownTypes) > 0
		BEGIN
			-- Split TearDownTypes CSV into a table
			WITH SplitTearDownTypes AS (
				SELECT value AS TearDownTypeId
				FROM STRING_SPLIT(@TearDownTypes, ',')
			)
			SELECT DISTINCT
				ty.[CommonTeardownTypeId],
				ty.[Name],
				ty.[Description],
				ty.[IsTechnician],
				ty.[IsDate],
				ty.[IsInspector],
				ty.[IsInspectorDate],
				ty.[IsDocument],
				ty.[TearDownCode],
				ty.[Sequence],
				ty.[MasterCompanyId],
				ISNULL(wotd.CommonWorkOrderTearDownId, 0) AS CommonWorkOrderTearDownId,
				CASE WHEN wotd.CommonWorkOrderTearDownId IS NOT NULL THEN 1 ELSE 0 END AS IsSelected,
				wotd.[ReasonId],
				wotd.[Memo],
				wotd.[TechnicianId],
				wotd.[TechnicianDate],
				wotd.[InspectorId],
				wotd.[InspectorDate],
				ISNULL(wotd.IsDocument, 0) AS IsDocumentAdded,
				ty.DocumentModuleName,
				ISNULL(wotd.WorkOrderId, 0) AS WorkOrderId,
				ISNULL(wotd.SubWorkOrderId, 0) AS SubWorkOrderId
			FROM [dbo].[CommonTeardownType] ty WITH(NOLOCK)
			LEFT JOIN [dbo].[CommonWorkOrderTearDown] wotd WITH(NOLOCK) ON ty.CommonTeardownTypeId = wotd.CommonTeardownTypeId
			   AND ty.MasterCompanyId = @MasterCompanyId
			   AND (
				   (@IsSubWorkOrder = 0 AND (wotd.IsSubWorkOrder IS NULL OR wotd.IsSubWorkOrder = 0)
						AND wotd.WorkOrderId = @WorkOrderId AND wotd.WorkFlowWorkOrderId = @WorkFlowWorkOrderId)
				   OR
				   (@IsSubWorkOrder = 1 AND wotd.IsSubWorkOrder = 1
						AND wotd.SubWorkOrderId = @WorkOrderId AND wotd.SubWOPartNoId = @SubWOPartNoId)
			   )
			WHERE ty.MasterCompanyId = @MasterCompanyId
			  AND ty.CommonTeardownTypeId IN (SELECT TRY_CAST(TearDownTypeId AS BIGINT) FROM SplitTearDownTypes)
			ORDER BY ty.Sequence;
		END
		ELSE
		BEGIN
			SELECT NULL;
		END
	END TRY
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetWOShippingLabel',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderId, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@WorkFlowWorkOrderId, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@IsSubWorkOrder, '') AS varchar(100)) + 
			'@Parameter5 = ''' + CAST(ISNULL(@SubWOPartNoId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
	END CATCH
END