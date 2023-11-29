/*************************************************************           
 ** File:[PROCCreateROFromROHistory]           
 ** Author:  Deep Patel
 ** Description: This stored procedure is used to create RO from RO History.
 ** Purpose:         
 ** Date:   28/07/2022
 ** PARAMETERS: @VendorRFQRepairOrderId bigint,@VendorRFQROPartRecordId bigint,@RepairOrderId bigint,@MasterCompanyId int,@CodeTypeId int,@Opr int
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    28/07/2022  Deep Patel     Created
-- EXEC [PROCCreateROFromROHistory] 13,0,0,2,25,1,1
************************************************************************/
CREATE PROCEDURE [dbo].[PROCCreateROFromROHistory]
--@VendorRFQRepairOrderId bigint,
--@VendorRFQROPartRecordId bigint,
@RepairOrderId bigint,
@MasterCompanyId int,
@CodeTypeId int,
--@Opr int,
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
		DECLARE @MCID INT=0;
		DECLARE @MSID BIGINT=0;
		DECLARE @CreateBy VARCHAR(100)='';
		DECLARE @UpdateBy VARCHAR(100)='';
		DECLARE @RID BIGINT=0;	
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
											 SELECT @RepairOrderNumber,[OpenDate],NULL,[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],
													[VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],
													[RequisitionerId],[Requisitioner],1,'',[StatusChangeDate],[Resale],[DeferredReceiver],
													[RoMemo],[Notes],NULL,NULL,NULL,[ManagementStructureId],[Level1],[Level2],
													[Level3],[Level4],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETDATE(),GETDATE(),1,
													0,@IsEnforceApproval,NULL,NULL
											  FROM dbo.RepairOrder WITH(NOLOCK) WHERE [RepairOrderId] = @RepairOrderId;
						
					UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNummber AS BIGINT) + 1 WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;
				
					SET @RID=IDENT_CURRENT('RepairOrder');
					SELECT @MSID=[ManagementStructureId],@MCID=[MasterCompanyId],
								 @CreateBy=[CreatedBy],@UpdateBy=[UpdatedBy]
							 FROM dbo.RepairOrder WITH(NOLOCK) WHERE [RepairOrderId]=@RepairOrderId;
					EXEC [DBO].[PROCAddROMSData] @RID,@MSID,@MCID,@CreateBy,@UpdateBy,24,1,0

					SELECT	@Result = IDENT_CURRENT('RepairOrder');								
				END
				ELSE
				BEGIN					
					SELECT	@Result = 0;
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
              , @AdhocComments     VARCHAR(150)    = 'PROCCreateROFromROHistory' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@RepairOrderId, '') AS varchar(100))
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