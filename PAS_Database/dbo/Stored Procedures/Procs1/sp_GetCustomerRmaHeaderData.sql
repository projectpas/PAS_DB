/*************************************************************           
 ** File:   [sp_GetCustomerInvoicedatabyInvoiceId]           
 ** Author:   Subhash Saliya
 ** Description: Get Customer Invoicedataby InvoiceId   
 ** Purpose:         
 ** Date:   18-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/18/2022   Subhash Saliya	 Created
    2	 19/06/2023   Ayesha Sultana	 ALtered - get new column ReceiverNum
	
 -- exec sp_GetCustomerInvoicedatabyInvoiceId 92,1    
**************************************************************/ 

CREATE Procedure [dbo].[sp_GetCustomerRmaHeaderData]
@RMAHeaderId bigint,
@Moduleid int =0
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			
			DECLARE @InvoiceStatus varchar(30)
			DECLARE @isWorkOrder bit
			DECLARE @InvoiceId bigint
			DECLARE @AddressCount int=0
			DECLARE @PartCount int=0
			SELECT @isWorkOrder =isWorkOrder,@InvoiceId= InvoiceId FROM [dbo].[CustomerRMAHeader]  WITH (NOLOCK) WHERE  RMAHeaderId =@RMAHeaderId

			SELECT top 1 @AddressCount = count(*) FROM CustomerRMAHeader CRMA  WITH (NOLOCK)
			INNER JOIN AllAddress RMAA WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAA.ReffranceId AND RMAA.IsShippingAdd = 1 and RMAA.ModuleId = @ModuleID
		    WHERE CRMA.RMAHeaderId = @RMAHeaderId


			Select top 1 @PartCount = count(*) from CustomerRMADeatils WITH (NOLOCK) where isnull(IsDeleted,0) = 0 and RMAHeaderId = @RMAHeaderId

			if(@isWorkOrder =1)
			BEGIN
			  SELECT @InvoiceStatus = InvoiceStatus FROM WorkOrderBillingInvoicing WOBI WITH (NOLOCK) WHERE  BillingInvoicingId =@InvoiceId
			END
			ELSE
			BEGIN
			  SELECT @InvoiceStatus = InvoiceStatus FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK) WHERE  SOBillingInvoicingId =@InvoiceId
			END


		    SELECT [RMAHeaderId]
			  ,CRM.[RMANumber]
			  ,CRM.[CustomerId]
			  ,CRM.[CustomerName]
			  ,CRM.[CustomerCode]
			  ,CRM.[CustomerContactId]
			  ,CRM.[ContactInfo]
			  ,CRM.[OpenDate]
			  ,CRM.[InvoiceId]
			  ,CRM.[InvoiceNo]
			  ,CRM.[InvoiceDate]
			  ,CRM.[RMAStatusId]
			  ,CRM.[RMAStatus]
			  ,CRM.[Iswarranty]
			  ,CRM.[ValidDate]
			  ,CRM.[RequestedId]
			  ,CRM.[Requestedby]
			  ,CRM.[ApprovedbyId]
			  ,CRM.[Approvedby]
			  ,CRM.[ApprovedDate]
			  ,CRM.[ReturnDate]
			  ,CRM.[WorkOrderId]
			  ,CRM.[WorkOrderNum]
			  ,CRM.[ManagementStructureId]
			  ,CRM.[Notes]
			  ,CRM.[Memo]
			  ,CRM.[MasterCompanyId]
			  ,CRM.[CreatedBy]
			  ,CRM.[UpdatedBy]
			  ,CRM.[CreatedDate]
			  ,CRM.[UpdatedDate]
			  ,CRM.[IsActive]
			  ,CRM.[IsDeleted]
			  ,CRM.[isWorkOrder]
			  ,CRM.ReferenceId
			  ,@InvoiceStatus As InvoiceStatus
			  ,RMAC.ValidDays
			  ,@AddressCount As AddressCount
			  ,@PartCount As PartCount
			  ,CRM.PDFPath
			  ,CRM.[ReceiverNum]
		  FROM [dbo].[CustomerRMAHeader] CRM  WITH (NOLOCK) 
		  LEFT JOIN RMACreditMemoSettings RMAC WITH (NOLOCK) ON CRM.MasterCompanyId = RMAC.MasterCompanyId
		  WHERE  RMAHeaderId =@RMAHeaderId AND ISNULL(CRM.IsDeleted,0)=0
         END
			
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetCustomerRmaHeaderData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RMAHeaderId, '') + ''
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