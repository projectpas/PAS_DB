/*************************************************************           
 ** File:   [USP_Lot_AddUpdateLotSetup]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Create or update Lot Setup Screen
 ** Date:   30/03/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    30/03/2023   Rajesh Gami     Created
**************************************************************
 EXEC USP_Lot_AddUpdateLotSetup 
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_Lot_AddUpdateLotSetup] 
@LotSetupId bigint OUTPUT,
@LotId bigint,
@IsUseMargin bit NULL,
@MarginPercentageId bigint NULL, 
@IsOverallLotCost bit NULL,
@IsCostToPN bit NULL,
@IsReturnCoreToLot bit NULL,
@IsMaintainStkLine bit NULL,
@CommissionCost decimal(10,2),
@MasterCompanyId int,
@CreatedBy varchar(50)
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
			   		
		IF (@LotSetupId = 0)
		BEGIN
		  INSERT INTO [dbo].[LotSetupMaster]
			   ([LotId] ,[IsUseMargin] ,[MarginPercentageId] ,[IsOverallLotCost] ,[IsCostToPN] ,[IsReturnCoreToLot] ,[IsMaintainStkLine]
			   ,[CommissionCost] ,[MasterCompanyId] ,[CreatedBy] ,[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
			VALUES
			   (@LotId ,@IsUseMargin ,@MarginPercentageId ,@IsOverallLotCost ,@IsCostToPN ,@IsReturnCoreToLot ,@IsMaintainStkLine
			   ,@CommissionCost ,@MasterCompanyId ,@CreatedBy ,@CreatedBy ,GETUTCDATE() ,GETUTCDATE() ,1 ,0)
		    SET @LotSetupId = @@IDENTITY;
		END
		ELSE
		BEGIN			
			UPDATE [dbo].[LotSetupMaster]
			   SET [IsUseMargin] = @IsUseMargin
			      ,[MarginPercentageId] = @MarginPercentageId
			      ,[IsOverallLotCost] = @IsOverallLotCost
			      ,[IsCostToPN] = @IsCostToPN
			      ,[IsReturnCoreToLot] = @IsReturnCoreToLot
			      ,[IsMaintainStkLine] = @IsMaintainStkLine
			      ,[CommissionCost] = @CommissionCost			      
			      ,[UpdatedBy] = @CreatedBy			     
			      ,[UpdatedDate] = GETUTCDATE()			      
			 WHERE [LotSetupId] = @LotSetupId; 		 
		END

		Select @LotSetupId AS LotSetupId 
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_Lot_AddUpdateLotSetup]',
            @ProcedureParameters varchar(3000) = '@LotSetupId = ''' + CAST(ISNULL(@LotSetupId, '') AS varchar(100))
            + '@LotId = ''' + CAST(ISNULL(@LotId, '') AS varchar(100))
            + '@IsUseMargin = ''' + CAST(ISNULL(@IsUseMargin, '') AS varchar(100))             
            + '@MarginPercentageId = ''' + CAST(ISNULL(@MarginPercentageId, '') AS varchar(100))
            + '@IsOverallLotCost = ''' + CAST(ISNULL(@IsOverallLotCost, '') AS varchar(100))
            + '@IsCostToPN = ''' + CAST(ISNULL(@IsCostToPN, '') AS varchar(100))
			+ '@IsReturnCoreToLot = ''' + CAST(ISNULL(@IsReturnCoreToLot, '') AS varchar(100))
			+ '@IsMaintainStkLine = ''' + CAST(ISNULL(@IsMaintainStkLine, '') AS varchar(100))
			+ '@CommissionCost = ''' + CAST(ISNULL(@CommissionCost, '') AS varchar(100))
			+ '@CreatedBy = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END