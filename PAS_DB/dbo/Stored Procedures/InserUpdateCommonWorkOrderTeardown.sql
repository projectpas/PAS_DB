
/*************************************************************           
 ** File:   [InserUpdateCommonWorkOrderTeardown]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used Insert/Update WorkOrder Teardown
 ** Purpose:         
 ** Date:   12/29/2021       
          
 ** PARAMETERS:   
 ** RETURN VALUE:           
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/29/2021   Vishal Suthar Created
**************************************************************/
CREATE PROCEDURE [dbo].[InserUpdateCommonWorkOrderTeardown]
    @CommonWorkOrderTeardownId bigint = 0,
    @CommonTeardownTypeId bigint = 0,
	@WorkOrderId bigint = 0,
	@WorkFlowWorkOrderId bigint = 0,
	@WOPartNoId bigint = null,
	@Memo varchar(max) = null,
	@ReasonId bigint = null,
	@technicianId bigint = null,
	@technicianDate datetime = null,
	@inspectorId bigint = null,
	@inspectorDate datetime = null,
	@IsDocument bit = 0,
	@MasterCompanyId bigint = 0,
	@CreatedBy varchar(200) = null,
	@UpdatedBy varchar(200) = null,
	@CreatedDate datetime,
	@UpdatedDate datetime,
	@IsActive bit,
	@IsDeleted bit
AS
BEGIN
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
     SET NOCOUNT ON

	 BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
			    IF (@CommonWorkOrderTeardownId = 0)
				BEGIN 
				      INSERT INTO [dbo].[CommonWorkOrderTearDown](
									[CommonTeardownTypeId]
								   ,[WorkOrderId]
								   ,[WorkFlowWorkOrderId]
								   ,[WOPartNoId]
								   ,[Memo]
								   ,[ReasonId]
								   ,[TechnicianId]
								   ,[TechnicianDate]
								   ,[InspectorId]
								   ,[InspectorDate]
								   ,[IsDocument]
								   ,[ReasonName]
								   ,[InspectorName]
								   ,[TechnicalName]
								   ,[CreatedBy]
								   ,[UpdatedBy]
								   ,[CreatedDate]
								   ,[UpdatedDate]
								   ,[IsActive]
								   ,[IsDeleted]
								   ,[MasterCompanyId])
									values(
									@CommonTeardownTypeId,
									@WorkOrderId,
									@WorkFlowWorkOrderId,
									@WOPartNoId,
									@Memo,
									@ReasonId,
									@technicianId,
									@technicianDate,
									@inspectorId,
									@inspectorDate,
									@IsDocument,
									NULL, NULL, NULL,
									@CreatedBy,
									@UpdatedBy,
									@CreatedDate,
									@UpdatedDate,
									@IsActive,
									@IsDeleted,
									@MasterCompanyId)

						SELECT @CommonWorkOrderTeardownId = SCOPE_IDENTITY()

						UPDATE WoTD SET
							WoTD.ReasonName = wdr.Reason,
							WoTD.InspectorName = E.FirstName + ' ' + E.LastName,
						    WoTD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
							WoTD.UpdatedBy = @UpdatedBy,
							WoTD.UpdatedDate = @UpdatedDate
						FROM [dbo].[CommonWorkOrderTearDown] WoTD WITH(NOLOCK)
						LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
						LEFT JOIN dbo.Employee E WITH(NOLOCK) ON @inspectorId = E.EmployeeId
						LEFT JOIN dbo.Employee E1 WITH(NOLOCK) ON @technicianId = E1.EmployeeId
						WHERE WoTD.CommonWorkOrderTearDownId = @CommonWorkOrderTeardownId
				END

				IF (@ReasonId = 0)
				  BEGIN
				     SET @ReasonId= null
				  END
                IF (@technicianId = 0)
				  BEGIN
				       SET @technicianId= null
				  END
				IF (@inspectorId = 0)
				  BEGIN
				     SET @inspectorId= null
				  END

				IF (ISNULL(@CommonWorkOrderTeardownId, 0) > 0)
				BEGIN 
					UPDATE WoTD SET
							WoTD.ReasonId = @ReasonId,
							WoTD.Memo = @memo,
							WoTD.[TechnicianId] = @technicianId,
							WoTD.[TechnicianDate] = @technicianDate,
							WoTD.[InspectorId] = @inspectorId,
							WoTD.[InspectorDate] = @inspectorDate,
							WoTD.[IsDocument] = @IsDocument,
							WoTD.ReasonName = wdr.Reason,
							WoTD.InspectorName = E.FirstName + ' ' + E.LastName,
						    WoTD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
							WoTD.UpdatedBy = @UpdatedBy,
							WoTD.UpdatedDate = @UpdatedDate
					FROM [dbo].[CommonWorkOrderTearDown] WoTD WITH(NOLOCK)
					LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
					LEFT JOIN dbo.Employee E WITH(NOLOCK) ON @inspectorId = E.EmployeeId
					LEFT JOIN dbo.Employee E1 WITH(NOLOCK) ON @technicianId = E1.EmployeeId
					WHERE WoTD.CommonWorkOrderTearDownId = @CommonWorkOrderTeardownId
				 END
			END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'InserUpdateCommonWorkOrderTeardown' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@CommonWorkOrderTeardownId, '') AS varchar(100)) 
			   + '@Parameter2 = ''' + CAST(ISNULL(@CommonWorkOrderTeardownId, '') AS varchar(100))
			   + '@Parameter3 = ''' + CAST(ISNULL(@WorkOrderId, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@WorkFlowWorkOrderId, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@Memo, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@ReasonId , '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@IsDocument , '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@UpdatedBy, '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@CreatedDate, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))
			   + '@Parameter13 = ''' + CAST(ISNULL(@IsActive , '') AS varchar(100))
			   + '@Parameter14 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			   + '@Parameter15 = ''' + CAST(ISNULL(@technicianId , '') AS varchar(100))
			   + '@Parameter16 = ''' + CAST(ISNULL(@technicianDate  , '') AS varchar(100))
			   + '@Parameter17 = ''' + CAST(ISNULL(@inspectorId  , '') AS varchar(100))
			   + '@Parameter18 = ''' + CAST(ISNULL(@inspectorDate , '') AS varchar(100))
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