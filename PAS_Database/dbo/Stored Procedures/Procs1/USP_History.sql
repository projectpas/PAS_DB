/*************************************************************               
 ** File:  [USP_History]               
 ** Author:  Amit Ghediya    
 ** Description: This stored procedure is used to save History Data.    
 ** Purpose:             
 ** Date:   20/03/2023          
              
 ** PARAMETERS: @ModuleId BIGINT    
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------		--------------------------------              
    1    20/03/2023  Amit Ghediya		Created    
    2    03/07/2023  Devendra Shekh		added new status code CreateVendorRMA    
    3    04/07/2023  Devendra Shekh		added new status code CreateVendorRMAPickTicket,VendorRMAPickTicketConfirmed,VendorRMAShipped    
    4    19/07/2023  Devendra Shekh		added new status code DeleteKit,DeleteKitPart,UnReservedParts  
	5    17/08/2023  Amit Ghediya		Updated HitoryText content.
	6    05/05/2024  HEMANT SALIYA		Added Customer ReOpen WO ,Change & Part Number Change
	7    18/10/2023  Devendra Shekh		added new status code REOPENEDFINISHEDGOODS    
	8    17/01/2025  Vishal Suthar		added new status code CreateWorkOrderTask, UpdateWorkOrderTaskDescrepancy and UpdateWorkOrderTaskResolution    
    9    01/09/2025  Moin Bloch		    Updated Added New Field [Activity]
	10   03/09/2025  Moin Bloch		    Updated Added TemplateText

-- EXEC USP_History 7,12,1,2,'WO stage change 1 to 2' ,'statgeId',1,1,NULL,NULL,NULL    
************************************************************************/    
CREATE   PROCEDURE [dbo].[USP_History]    
 @ModuleId BIGINT,    
 @RefferenceId BIGINT,    
 @SubModuleId BIGINT,    
 @SubRefferenceId BIGINT,    
 @OldValue VARCHAR(MAX),    
 @NewValue VARCHAR(MAX),    
 @HistoryText VARCHAR(MAX) = NULL,    
 @StatusCode VARCHAR(256),    
 @MasterCompanyId INT = 1,    
 @CreatedBy VARCHAR(256) = NULL,    
 @CreatedDate DATETIME = NULL,    
 @UpdatedBy VARCHAR(256) = NULL,    
 @UpdatedDate DATETIME = NULL    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY     
    
  DECLARE @TemplateBody NVARCHAR(MAX);    
  DECLARE @RequestorName VARCHAR(256);    
  DECLARE @ApproverName VARCHAR(256);    
  DECLARE @WorkOrderNum VARCHAR(256);
  DECLARE @TemplateText VARCHAR(50);  
    
  SELECT @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @StatusCode;    
  SELECT @WorkOrderNum = [WorkOrderNum] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @RefferenceId;    
  
  IF (@StatusCode = 'Traveler' OR @StatusCode = 'Freight' OR @StatusCode  = 'Charges' OR @StatusCode = 'MaterialPickticketConfirmed' OR @StatusCode = 'MaterialPicket' OR @StatusCode = 'MPNPickticketConfirmed' OR @StatusCode = 'MPNPickticket' OR @StatusCode = 'Settlement' OR @StatusCode = 'SettlementOutGoing' OR @StatusCode = 'FinishedGoods' OR @StatusCode = 'CloseWO' OR 
  @StatusCode = 'Releasefrom' OR @StatusCode = 'ReleasefromChange' OR @StatusCode = 'ReleasefromisLocked' OR @StatusCode = 'Shipping' OR @StatusCode = 'Invoicing' OR @StatusCode = 'ShippingPost' OR @StatusCode = 'AddKit' OR @StatusCode = 'CreateWorkOrder' OR @StatusCode = 'UpdateWorkScope' OR 
  @StatusCode = 'UpdateWorkOrderPriority' OR @StatusCode = 'UpdateWorkOrderPublication' OR @StatusCode = 'AddWorkFlow' OR @StatusCode = 'UpdateWorkFlow' OR @StatusCode = 'CreateVendorRMA' OR @StatusCode = 'AddVendorRMAPN' OR @StatusCode = 'CreateVendorRMAPickTicket' 
  OR @StatusCode = 'VendorRMAPickTicketConfirmed' OR @StatusCode = 'VendorRMAShipped' OR @StatusCode = 'CreateVendorCreditMemo' OR @StatusCode = 'UpdateVendorRMAPartQty' OR @StatusCode = 'UpdateVendorRMAReturnReason'
  OR @StatusCode = 'DeleteKit' OR @StatusCode = 'DeleteKitPart' OR @StatusCode = 'UnReservedParts' OR @StatusCode = 'StageChange' OR @StatusCode = 'AddPN' OR @StatusCode = 'IssuedParts' OR @StatusCode = 'ReserveParts' OR 
  @StatusCode = 'UnIssuedParts' OR @StatusCode = 'CustomerChange' OR @StatusCode = 'PartNumberChange' OR @StatusCode = 'REOPENCLOSEDWO' OR @StatusCode = 'SERNUMCHANGE' OR @StatusCode = 'CUSTREFCHANGE' OR @StatusCode = 'REOPENEDFINISHEDGOODS' OR @StatusCode = 'CreateWorkOrderTask' OR @StatusCode = 'UpdateWorkOrderTaskDescrepancy' OR @StatusCode = 'UpdateWorkOrderTaskResolution'
  OR @StatusCode = 'DeleteWorkOrderTask' OR @StatusCode = 'CreateWorkOrderTaskInstruction' OR @StatusCode = 'TravelerDelete')    
  BEGIN        
	SELECT @TemplateText = [TemplateText] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @StatusCode; 
	
	IF(@StatusCode = 'ReleasefromisLocked')
	BEGIN
		SET @TemplateText = CASE WHEN @NewValue = 'False' THEN 'Release Form UnLocked' ELSE 'Release Form Locked' END
	END
	
   INSERT INTO [dbo].[History]    
       ([ModuleId]    
       ,[RefferenceId]    
       ,[SubModuleId]    
       ,[SubRefferenceId]    
       ,[OldValue]    
       ,[NewValue]    
       ,[HistoryText]    
       ,[FieldsName]    
       ,[MasterCompanyId]    
       ,[CreatedBy]    
       ,[CreatedDate]    
       ,[UpdatedBy]    
       ,[UpdatedDate]
	   ,[Activity])    
    VALUES    
       (@ModuleId    
       ,@RefferenceId    
       ,@SubModuleId    
       ,@SubRefferenceId    
       ,@OldValue    
       ,@NewValue    
       ,@HistoryText    
       ,'No'    
       ,CASE WHEN ISNULL(@MasterCompanyId,0) = 0 THEN 1 ELSE @MasterCompanyId END    
       ,@CreatedBy    
       ,GETUTCDATE()    
       ,@CreatedBy    
       ,GETUTCDATE()
	   ,@TemplateText)    
  END    
  END TRY        
 BEGIN CATCH    
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
        , @AdhocComments     VARCHAR(150)    = 'USP_History'     
        ,@ProcedureParameters VARCHAR(3000) = '@OldValue = ''' + CAST(ISNULL(@OldValue, '') AS VARCHAR(100))      
   + '@OldValue = ''' + CAST(ISNULL(@OldValue, '') AS VARCHAR(100))       
   + '@NewValue = ''' + CAST(ISNULL(@NewValue, '') AS VARCHAR(100))       
   + '@HistoryText = ''' + CAST(ISNULL(@HistoryText, '') AS VARCHAR(100))       
   + '@StatusCode = ''' + CAST(ISNULL(@StatusCode, '') AS VARCHAR(100))        
   + '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))       
   + '@CreatedBy = ''' + CAST(ISNULL(@CreatedBy, '') AS VARCHAR(100))       
   + '@CreatedDate = ''' + CAST(ISNULL(@CreatedDate, '') AS VARCHAR(100))       
   + '@UpdatedBy = ''' + CAST(ISNULL(@UpdatedBy, '') AS VARCHAR(100))       
   + '@UpdatedDate = ''' + CAST(ISNULL(@UpdatedDate, '') AS VARCHAR(100))       
        , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
        exec spLogException     
                @DatabaseName           = @DatabaseName    
                , @AdhocComments          = @AdhocComments    
                , @ProcedureParameters = @ProcedureParameters    
                , @ApplicationName        =  @ApplicationName    
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
        RETURN(1);    
 END CATCH    
END