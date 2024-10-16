﻿/*************************************************************           
 ** File:   [CreateUpdateCreditMemoHeader]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to create and update Credit Memo Details
 ** Purpose:         
 ** Date:   18/04/2022      
          
 ** PARAMETERS: @RMAHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1    18/04/2022  Moin Bloch					Created
    2    03/07/2023  Devendra Shekh				added new condition for rmaid and rmanum
	3    08/01/2023  AMIT GHEDIYA				Handle Multiple record cash.
	4    20/02/2023 Devendra Shekh				added new param
	5    19/04/2023 Devendra Shekh				added new param(IsExchange)
	6    22/04/2023 Devendra Shekh				added new param(InvoiceTypeId) and removed IsExchange
     
-- EXEC CreateUpdateCreditMemoHeader 1
************************************************************************/
CREATE   PROCEDURE [dbo].[CreateUpdateCreditMemoHeader]
	@CreditMemoHeaderId bigint=NULL,
	@CreditMemoNumber varchar(50)=NULL,
	@RMAHeaderId bigint=NULL,
	@RMANumber varchar(50)=NULL,
	@InvoiceId  bigint=NULL,
	@InvoiceNumber varchar(50)=NULL,
	@InvoiceDate datetime2(7)=NULL,
	@StatusId int=NULL,
	@Status varchar(50)=NULL,
	@CustomerId bigint=NULL,
	@CustomerName varchar(50)=NULL,
	@CustomerCode varchar(50)=NULL, 
	@CustomerContactId bigint=NULL,
	@CustomerContact varchar(50)=NULL, 
	@CustomerContactPhone varchar(20)=NULL,
	@IsWarranty bit=NULL,
	@IsAccepted bit=NULL,
	@ReasonId bigint=NULL,
	@DeniedMemo nvarchar(max)=NULL, 
	@RequestedById bigint=NULL,
	@RequestedBy varchar(100)=NULL, 
	@ApproverId bigint=NULL,
	@ApprovedBy varchar(100)=NULL,
	@WONum varchar(50)=NULL,
	@WorkOrderId bigint=NULL,
	@Originalwosonum varchar(50)=NULL, 
	@Memo nvarchar(max)=NULL,
	@Notes nvarchar(max)=NULL,
	@ManagementStructureId bigint=NULL,
	@IsEnforce bit=NULL,
	@MasterCompanyId int=NULL,
	@CreatedBy varchar(256)=NULL,
	@UpdatedBy varchar(256)=NULL,
	@CreatedDate datetime2(7)=NULL,
	@UpdatedDate datetime2(7)=NULL,
	@IsActive bit=NULL,
	@IsDeleted bit=NULL,
	@IsWorkOrder bit=NULL,
	@ReferenceId bigint=NULL,
	@ReturnDate datetime2(7)=NULL,
	@IsStandAloneCM bit=NULL,
	@InvoiceTypeId int=NULL,
	@Result bigint OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN

			DECLARE @rmaId BIGINT = null;
			DECLARE @rmaNum VARCHAR(100) = null;
			DECLARE @multiRMAId BIGINT = null;

			SET @multiRMAId = (SELECT COUNT(RMAHeaderId) FROM dbo.CustomerRMAHeader WITH(NOLOCK) WHERE ReferenceId = @ReferenceId AND isWorkOrder = @IsWorkOrder);

			IF(@ReferenceId IS NOT NULL AND @multiRMAId = 1)
			BEGIN 
				SET @rmaId = (SELECT RMAHeaderId FROM dbo.CustomerRMAHeader WITH(NOLOCK) WHERE ReferenceId = @ReferenceId AND isWorkOrder = @IsWorkOrder)
				SET @rmaNum = (SELECT RMANumber FROM dbo.CustomerRMAHeader WITH(NOLOCK) WHERE ReferenceId = @ReferenceId AND isWorkOrder = @IsWorkOrder)
			END

			IF(@RMANumber IS NOT NULL)
			BEGIN
				SET @rmaId = (SELECT RMAHeaderId FROM dbo.CustomerRMAHeader WITH(NOLOCK) WHERE RMANumber = @RMANumber)
				SET @rmaNum = @RMANumber;
			END

			IF (@CreditMemoHeaderId IS NULL OR @CreditMemoHeaderId=0)
			BEGIN
				INSERT INTO [dbo].[CreditMemo]([CreditMemoNumber],[RMAHeaderId],[RMANumber],[InvoiceId],[InvoiceNumber],[InvoiceDate],[StatusId],[Status],
											   [CustomerId],[CustomerName],[CustomerCode],[CustomerContactId],[CustomerContact],[CustomerContactPhone],
											   [IsWarranty],[IsAccepted],[ReasonId],[DeniedMemo],[RequestedById],[RequestedBy],[ApproverId],[ApprovedBy],
											   [WONum],[WorkOrderId],[Originalwosonum],[Memo],[Notes],[ManagementStructureId],[IsEnforce],[MasterCompanyId],
                                               [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsWorkOrder],[ReferenceId],[ReturnDate], [IsStandAloneCM],[InvoiceTypeId])
										VALUES (@CreditMemoNumber,@rmaId,@rmaNum,@InvoiceId,@InvoiceNumber,@InvoiceDate,@StatusId,@Status,
												@CustomerId,@CustomerName,@CustomerCode,@CustomerContactId,@CustomerContact,@CustomerContactPhone,  
												@IsWarranty,@IsAccepted,@ReasonId,@DeniedMemo,@RequestedById,@RequestedBy,@ApproverId,@ApprovedBy,  
												@WONum,@WorkOrderId,@Originalwosonum,@Memo,@Notes,@ManagementStructureId,@IsEnforce,@MasterCompanyId,
												@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,@IsActive,@IsDeleted,@IsWorkOrder,@ReferenceId,@ReturnDate, @IsStandAloneCM,@InvoiceTypeId);

				SELECT	@Result = IDENT_CURRENT('CreditMemo');

				EXEC [DBO].[UpdateCreditMemoDetails] @Result;
			END		
			ELSE
			BEGIN
				UPDATE [dbo].[CreditMemo] SET [StatusId]=@StatusId,[IsWarranty]=@IsWarranty,[IsAccepted]=@IsAccepted,[ReasonId]=@ReasonId,
											  [DeniedMemo]=@DeniedMemo,[RequestedById]=@RequestedById,[ApproverId]=@ApproverId,
											  [Memo]=@Memo,[Notes]=@Notes,[ManagementStructureId]=@ManagementStructureId,[IsEnforce]=@IsEnforce,
											  [UpdatedBy]=@UpdatedBy,[UpdatedDate]=@UpdatedDate
									    WHERE [CreditMemoHeaderId] = @CreditMemoHeaderId;
				SELECT	@Result = @CreditMemoHeaderId;

				EXEC [DBO].[UpdateCreditMemoDetails] @CreditMemoHeaderId;
			END
		END
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CreateUpdateCreditMemoHeader' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@CreditMemoHeaderId, '') AS varchar(100))
													+ '@Parameter2 = ''' + CAST(ISNULL(@CreditMemoNumber, '') AS varchar(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@RMAHeaderId, '') AS varchar(100)) 
													+ '@Parameter4 = ''' + CAST(ISNULL(@RMANumber, '') AS varchar(100)) 
													+ '@Parameter5 = ''' + CAST(ISNULL(@InvoiceId, '') AS varchar(100)) 
													+ '@Parameter6 = ''' + CAST(ISNULL(@InvoiceNumber, '') AS varchar(100)) 
													+ '@Parameter7 = ''' + CAST(ISNULL(@InvoiceDate, '') AS varchar(100)) 
													+ '@Parameter8 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100)) 
													+ '@Parameter9 = ''' + CAST(ISNULL(@Status, '') AS varchar(100)) 
													+ '@Parameter10 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100)) 
													+ '@Parameter11 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END