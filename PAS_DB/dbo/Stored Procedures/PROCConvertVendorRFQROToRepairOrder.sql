
/*************************************************************           
 ** File:   [PROCConvertVendorRFQROToRepairOrder]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to convert vendor RFQ RO to Repair Order  
 ** Purpose:         
 ** Date:   04/01/2022        
          
 ** PARAMETERS: @VendorRFQRepairOrderId bigint,@VendorRFQROPartRecordId bigint,@RepairOrderId bigint,@MasterCompanyId int,@CodeTypeId int,@Opr int
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/01/2022  Moin Bloch     Created
     
-- EXEC [PROCConvertVendorRFQROToRepairOrder] 13,0,0,2,25,1,1
************************************************************************/

CREATE PROCEDURE [dbo].[PROCConvertVendorRFQROToRepairOrder]
@VendorRFQRepairOrderId bigint,
@VendorRFQROPartRecordId bigint,
@RepairOrderId bigint,
@MasterCompanyId int,
@CodeTypeId int,
@Opr int,
@Result int OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	DECLARE @CurrentNummber bigint;
	DECLARE @CodePrefix VARCHAR(50);
	DECLARE @CodeSufix VARCHAR(50);	
	DECLARE @RepairOrderNumber VARCHAR(250);
	DECLARE @IsEnforceApproval bit;
	DECLARE @RONumber VARCHAR(250);
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN  
		IF(@Opr = 1)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM dbo.RepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId)
			BEGIN			
				SELECT @CurrentNummber = [CurrentNummber],@CodePrefix = [CodePrefix],@CodeSufix = [CodeSufix] FROM dbo.CodePrefixes WITH(NOLOCK)
						WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;

				SELECT TOP 1 @IsEnforceApproval = [IsEnforceApproval] FROM dbo.RepairOrderSettingMaster WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
					
				IF(@CurrentNummber!='' OR @CurrentNummber!=NULL)
				BEGIN
					SET @RepairOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix));
					INSERT INTO [dbo].[RepairOrder]([RepairOrderNumber],[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],
													[VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],
													[RequisitionerId],[Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],
													[RoMemo],[Notes],[ApproverId],[ApprovedBy],[ApprovedDate],[ManagementStructureId],[Level1],[Level2],
													[Level3],[Level4],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],
													[IsDeleted],[IsEnforce],[PDFPath],[VendorRFQRepairOrderId])
											 SELECT @RepairOrderNumber,[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],
													[VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],
													[RequisitionerId],[Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],
													[Memo],[Notes],NULL,NULL,NULL,[ManagementStructureId],[Level1],[Level2],
													[Level3],[Level4],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETDATE(),GETDATE(),1,
													0,@IsEnforceApproval,NULL,@VendorRFQRepairOrderId
											  FROM dbo.VendorRFQRepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId;
						
					UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNummber AS BIGINT) + 1 WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;
				
				    --UPDATE dbo.VendorRFQRepairOrder SET StatusId=2,[Status] = 'Pending' WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId;
					--UPDATE dbo.VendorRFQRepairOrderPart SET [RepairOrderId] = IDENT_CURRENT('RepairOrder'),[RepairOrderNumber] = @RepairOrderNumber 
					--							    WHERE [VendorRFQRepairOrderId]=@VendorRFQRepairOrderId;
					SELECT	@Result = IDENT_CURRENT('RepairOrder');								
				END
				ELSE
				BEGIN					
					SELECT	@Result = 0;
				END
			END
		    ELSE
		    BEGIN			
			     SELECT	@Result = -1;
		    END
		END	
		IF(@Opr = 2)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM dbo.RepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId)
			BEGIN			
				SELECT @CurrentNummber = [CurrentNummber],@CodePrefix = [CodePrefix],@CodeSufix = [CodeSufix] FROM dbo.CodePrefixes WITH(NOLOCK)
						WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;

				SELECT TOP 1 @IsEnforceApproval = [IsEnforceApproval] FROM dbo.RepairOrderSettingMaster WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
					
				IF(@CurrentNummber!='' OR @CurrentNummber!=NULL)
				BEGIN
					SET @RepairOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix));
					INSERT INTO [dbo].[RepairOrder]([RepairOrderNumber],[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],
													[VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],
													[RequisitionerId],[Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],
													[RoMemo],[Notes],[ApproverId],[ApprovedBy],[ApprovedDate],[ManagementStructureId],[Level1],[Level2],
													[Level3],[Level4],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],
													[IsDeleted],[IsEnforce],[PDFPath],[VendorRFQRepairOrderId])
											 SELECT @RepairOrderNumber,[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],
													[VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],
													[RequisitionerId],[Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],
													[Memo],[Notes],NULL,NULL,NULL,[ManagementStructureId],[Level1],[Level2],
													[Level3],[Level4],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETDATE(),GETDATE(),1,
													0,@IsEnforceApproval,NULL,@VendorRFQRepairOrderId
											  FROM dbo.VendorRFQRepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId;
						
					UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNummber AS BIGINT) + 1 WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;
				
				    --UPDATE dbo.VendorRFQRepairOrder SET StatusId=2,[Status] = 'Pending' WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId;
					--UPDATE dbo.VendorRFQRepairOrderPart SET [RepairOrderId] = IDENT_CURRENT('RepairOrder'),[RepairOrderNumber] = @RepairOrderNumber 
					--							    WHERE [VendorRFQRepairOrderId]=@VendorRFQRepairOrderId;
					SELECT	@Result = IDENT_CURRENT('RepairOrder');								
				END
				ELSE
				BEGIN					
					SELECT	@Result = 0;
				END
			END
		    ELSE
		    BEGIN				
				  SELECT @Result = (SELECT RepairOrderId FROM dbo.RepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId);					 
		    END
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
              , @AdhocComments     VARCHAR(150)    = 'PROCConvertVendorRFQROToRepairOrder' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@VendorRFQRepairOrderId, '') AS varchar(100))
													+ '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@CodeTypeId, '') AS varchar(100))  
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