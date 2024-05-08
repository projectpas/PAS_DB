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
	5    05/05/2024  HEMANT SALIYA		Added Customer ReOpen WO ,Change & Part Number Change
         
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
    
  SELECT @TemplateBody = TemplateBody FROM HistoryTemplate WHERE TemplateCode = @StatusCode;    
  SELECT @WorkOrderNum = WorkOrderNum FROM WorkOrder WHERE WorkOrderId = @RefferenceId;    
  
  IF (@StatusCode = 'Traveler' OR @StatusCode = 'Freight' OR @StatusCode  = 'Charges' OR @StatusCode = 'MaterialPickticketConfirmed' OR @StatusCode = 'MaterialPicket' OR @StatusCode = 'MPNPickticketConfirmed' OR @StatusCode = 'MPNPickticket' OR @StatusCode = 'Settlement' OR @StatusCode = 'SettlementOutGoing' OR @StatusCode = 'FinishedGoods' OR @StatusCode = 'CloseWO' OR 
  @StatusCode = 'Releasefrom' OR @StatusCode = 'ReleasefromChange' OR @StatusCode = 'ReleasefromisLocked' OR @StatusCode = 'Shipping' OR @StatusCode = 'Invoicing' OR @StatusCode = 'ShippingPost' OR @StatusCode = 'AddKit' OR @StatusCode = 'CreateWorkOrder' OR @StatusCode = 'UpdateWorkScope' OR 
  @StatusCode = 'UpdateWorkOrderPriority' OR @StatusCode = 'UpdateWorkOrderPublication' OR @StatusCode = 'AddWorkFlow' OR @StatusCode = 'UpdateWorkFlow' OR @StatusCode = 'CreateVendorRMA' OR @StatusCode = 'AddVendorRMAPN' OR @StatusCode = 'CreateVendorRMAPickTicket' 
  OR @StatusCode = 'VendorRMAPickTicketConfirmed' OR @StatusCode = 'VendorRMAShipped' OR @StatusCode = 'CreateVendorCreditMemo' OR @StatusCode = 'UpdateVendorRMAPartQty' OR @StatusCode = 'UpdateVendorRMAReturnReason'
  OR @StatusCode = 'DeleteKit' OR @StatusCode = 'DeleteKitPart' OR @StatusCode = 'UnReservedParts' OR @StatusCode = 'StageChange' OR @StatusCode = 'AddPN' OR @StatusCode = 'IssuedParts' OR @StatusCode = 'ReserveParts' OR 
  @StatusCode = 'UnIssuedParts' OR @StatusCode = 'CustomerChange' OR @StatusCode = 'PartNumberChange' OR @StatusCode = 'REOPENCLOSEDWO' OR @StatusCode = 'SERNUMCHANGE' OR @StatusCode = 'CUSTREFCHANGE')    
  BEGIN    
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
       ,[UpdatedDate])    
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
       ,GETUTCDATE())    
  END    
  END TRY        
 BEGIN CATCH    
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
        , @AdhocComments     VARCHAR(150)    = 'USP_History'     
        ,@ProcedureParameters VARCHAR(3000) = '@OldValue = ''' + CAST(ISNULL(@OldValue, '') AS varchar(100))      
   + '@OldValue = ''' + CAST(ISNULL(@OldValue, '') as varchar(100))       
   + '@NewValue = ''' + CAST(ISNULL(@NewValue, '') as varchar(100))       
   + '@HistoryText = ''' + CAST(ISNULL(@HistoryText, '') as varchar(100))       
   + '@StatusCode = ''' + CAST(ISNULL(@StatusCode, '') as varchar(100))        + '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))       
   + '@CreatedBy = ''' + CAST(ISNULL(@CreatedBy, '') as varchar(100))       
   + '@CreatedDate = ''' + CAST(ISNULL(@CreatedDate, '') as varchar(100))       
   + '@UpdatedBy = ''' + CAST(ISNULL(@UpdatedBy, '') as varchar(100))       
   + '@UpdatedDate = ''' + CAST(ISNULL(@UpdatedDate, '') as varchar(100))       
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