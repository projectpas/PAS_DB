﻿/*************************************************************           
 ** File:   [CreateUpdateCustomerRMAHeader]           
 ** Author:   Subhash Saliya
 ** Description: Create Update Customer RMAHeader
 ** Purpose:         
 ** Date:   18-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/18/2022   Subhash Saliya 		Created
    2	 19/06/2023   Ayesha Sultana  		Altered - Added ReceiverNum to the DB and SP
	3	 25/12/2023   AMIT GHEDIYA 		    Altered - Added ReturnDate when create from WO.
	
 -- exec CreateUpdateCustomerRMAHeader 92,1    
**************************************************************/ 
CREATE PROCEDURE [dbo].[CreateUpdateCustomerRMAHeader]
@RMAHeaderId bigint = NULL,
@RMANumber varchar(50) = NULL,
@InvoiceId  bigint = NULL,
@InvoiceNo varchar(50) = NULL,  
@InvoiceDate datetime2(7) = NULL,
@RMAStatusId int = NULL,
@RMAStatus varchar(50)= NULL,
@CustomerId bigint = NULL,
@CustomerName varchar(50) = NULL,  
@CustomerCode varchar(50) = NULL,
@ContactInfo varchar(50) = NULL,
@CustomerContactId bigint = NULL,
@IsWarranty bit = 0,
@ValidDate datetime= NULL,
@RequestedId bigint = NULL,
@Requestedby varchar(100) = NULL,  
@ApprovedbyId bigint = NULL,
@Approvedby varchar(100) = NULL, 
@ApprovedDate datetime = NULL ,
@ReturnDate datetime = NULL,
@WorkOrderId bigint = NULL,
@WorkOrderNum varchar(50) = NULL, 
@ReceiverNum varchar(30) = NULL, 
@Memo nvarchar(max) = NULL, 
@Notes nvarchar(max) = NULL, 
@ManagementStructureId bigint = NULL,
@MasterCompanyId int,
@CreatedBy varchar(256),  
@UpdatedBy varchar(256),  
@CreatedDate datetime2(7),
@UpdatedDate datetime2(7),
@IsActive bit = NULL,
@IsDeleted bit = NULL,
@OpenDate  datetime2(7) = NULL,
@isWorkOrder bit = NULL,
@ReferenceId bigint = NULL,
@ModuleId INT =0,
@Result bigint =1 OUTPUT

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN

		    DECLARE @RC int
			DECLARE @Opr int
			DECLARE @MSDetailsId bigint
			IF (@RMAHeaderId IS NULL OR @RMAHeaderId=0)
			BEGIN
				INSERT INTO [dbo].[CustomerRMAHeader]([RMANumber],[InvoiceId],[InvoiceNo],[InvoiceDate],RMAStatusId,RMAStatus,
											   [CustomerId],[CustomerName],[CustomerCode],[CustomerContactId],ContactInfo,
											   [IsWarranty],RequestedId,Requestedby,ApprovedbyId,[ApprovedBy],ValidDate,ApprovedDate,OpenDate,
											   [WorkOrderId],WorkOrderNum,[ReceiverNum],[Memo],[Notes],[ManagementStructureId],[MasterCompanyId],
                                               [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[isWorkOrder],ReferenceId,[ReturnDate])
										VALUES (@RMANumber,@InvoiceId,@InvoiceNo,@InvoiceDate,@RMAStatusId,@RMAStatus,
												@CustomerId,@CustomerName,@CustomerCode,@CustomerContactId,@ContactInfo,  
												@IsWarranty,@RequestedId,@RequestedBy,@ApprovedbyId,@ApprovedBy,@ValidDate,@ApprovedDate,@OpenDate, 
												@WorkOrderId,@WorkOrderNum,@ReceiverNum,@Memo,@Notes,@ManagementStructureId,@MasterCompanyId,
												@CreatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),@IsActive,@IsDeleted,@isWorkOrder,@ReferenceId,@ReturnDate);

				SELECT	@Result = IDENT_CURRENT('CustomerRMAHeader');
			    SELECT @Result as RMAHeaderId
				EXEC [DBO].[UpdateCUstomerRMADetails] @Result;

				
			END
			ELSE
			BEGIN

			 UPDATE [dbo].[CustomerRMAHeader]
                 SET [RMANumber] = @RMANumber
				,[CustomerId] = @CustomerId
				,[CustomerName] = @CustomerName
				,[CustomerCode] = @CustomerCode
				,[CustomerContactId] = @CustomerContactId
				,[ContactInfo]=@ContactInfo
				,[OpenDate] = @OpenDate
				,[InvoiceId] = @InvoiceId
				,[InvoiceNo] = @InvoiceNo
				,[InvoiceDate] = @InvoiceDate
				,[RMAStatusId] = @RMAStatusId
				,[RMAStatus] = @RMAStatus
				,[Iswarranty] = @Iswarranty
				,[ValidDate] = @ValidDate
				,[RequestedId] = @RequestedId
				,[Requestedby] = @Requestedby
				,[ApprovedbyId] = @ApprovedbyId
				,[Approvedby] = @Approvedby
				,[ApprovedDate] = @ApprovedDate
				,[ReturnDate] = @ReturnDate
				,[WorkOrderId] = @WorkOrderId
				,[WorkOrderNum] = @WorkOrderNum
				,[ReceiverNum]=@ReceiverNum
				,[ManagementStructureId] = @ManagementStructureId
				,[Notes] = @Notes
				,[Memo] = @Memo
				,[UpdatedBy] = @UpdatedBy
				,[UpdatedDate] = GETUTCDATE()
				
                 WHERE RMAHeaderId = @RMAHeaderId

				 SELECT @RMAHeaderId as RMAHeaderId
				 set @Result= @RMAHeaderId
				 EXEC [DBO].[UpdateCUstomerRMADetails] @RMAHeaderId;

				 -----------------------------------------------------------------
						--for add new Stockline
				 -----------------------------------------------------------------


				 Declare @StatusID int=0

				 select @StatusID=RMAStatusId from RMAStatus  where UPPER(Description) =UPPER('Fulfilled')
				 if(@RMAStatusId=@StatusID)
				 begin


				      IF OBJECT_ID(N'tempdb..#RMADeatils') IS NOT NULL
							BEGIN
							DROP TABLE #RMADeatils
							END
							CREATE TABLE #RMADeatils
							(
							ID int IDENTITY,
							RMADeatilsId bigint
							)
							INSERT INTO #RMADeatils (RMADeatilsId)
							  SELECT RMADeatilsId 
						        FROM CustomerRMADeatils  where RMAHeaderId=@RMAHeaderId 

						    DECLARE @RMADeatilsId bigint;
							DECLARE @LoopID as int
							SELECT  @LoopID = MAX(ID) FROM #RMADeatils
							WHILE(@LoopID > 0)
							BEGIN
							  SELECT @RMADeatilsId = RMADeatilsId FROM #RMADeatils WHERE ID  = @LoopID
									IF NOT EXISTS (SELECT RMADeatilsId FROM Stockline WHERE RMADeatilsId = @RMADeatilsId)
								  BEGIN 

										EXEC [CreateStocklineForCustomerRMADeatils] @RMADeatilsId,@ModuleId
								 END

							SET @LoopID = @LoopID - 1;
							END 


				 end

			END
		END
		COMMIT
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CreateUpdateCreditMemoHeader' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@RMAHeaderId, '') AS varchar(100))
													+ '@Parameter2 = ''' + CAST(ISNULL(@RMANumber, '') AS varchar(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@InvoiceId, '') AS varchar(100)) 
													+ '@Parameter4 = ''' + CAST(ISNULL(@InvoiceNo, '') AS varchar(100)) 
													+ '@Parameter5 = ''' + CAST(ISNULL(@InvoiceDate, '') AS varchar(100)) 
													+ '@Parameter6 = ''' + CAST(ISNULL(@RMAStatusId, '') AS varchar(100)) 
													+ '@Parameter7 = ''' + CAST(ISNULL(@RMAStatus, '') AS varchar(100)) 
													+ '@Parameter8 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100)) 
													+ '@Parameter9 = ''' + CAST(ISNULL(@CustomerName, '') AS varchar(100)) 
													+ '@Parameter10 = ''' + CAST(ISNULL(@CustomerCode, '') AS varchar(100)) 
													+ '@Parameter11 = ''' + CAST(ISNULL(@ContactInfo, '') AS varchar(100)) 
													+ '@Parameter2 = ''' + CAST(ISNULL(@CustomerContactId, '') AS varchar(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@IsWarranty, '') AS varchar(100)) 
													+ '@Parameter4 = ''' + CAST(ISNULL(@ValidDate, '') AS varchar(100)) 
													+ '@Parameter5 = ''' + CAST(ISNULL(@RequestedId, '') AS varchar(100)) 
													+ '@Parameter6 = ''' + CAST(ISNULL(@Requestedby, '') AS varchar(100)) 
													+ '@Parameter7 = ''' + CAST(ISNULL(@ApprovedbyId, '') AS varchar(100)) 
													+ '@Parameter8 = ''' + CAST(ISNULL(@Approvedby, '') AS varchar(100)) 
													+ '@Parameter9 = ''' + CAST(ISNULL(@ApprovedDate, '') AS varchar(100)) 
													+ '@Parameter10 = ''' + CAST(ISNULL(@ReturnDate, '') AS varchar(100)) 
													+ '@Parameter11 = ''' + CAST(ISNULL(@WorkOrderId, '') AS varchar(100)) 

													+ '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderNum, '') AS varchar(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@ReceiverNum, '') AS varchar(100))
													+ '@Parameter4 = ''' + CAST(ISNULL(@Memo, '') AS varchar(100)) 
													+ '@Parameter5 = ''' + CAST(ISNULL(@Notes, '') AS varchar(100)) 
													+ '@Parameter6 = ''' + CAST(ISNULL(@ManagementStructureId, '') AS varchar(100)) 
													+ '@Parameter7 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 
													+ '@Parameter8 = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100)) 
													+ '@Parameter9 = ''' + CAST(ISNULL(@UpdatedBy, '') AS varchar(100)) 
													+ '@Parameter10 = ''' + CAST(ISNULL(@CreatedDate, '') AS varchar(100)) 
													+ '@Parameter11 = ''' + CAST(ISNULL(@UpdatedDate, '') AS varchar(100)) 
													+ '@Parameter11 = ''' + CAST(ISNULL(@IsActive, '') AS varchar(100)) 
												    + '@Parameter11 = ''' + CAST(ISNULL(@IsDeleted, '') AS varchar(100))
													
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