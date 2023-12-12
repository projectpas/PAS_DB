/*************************************************************           
 ** File:   [USP_Lot_AddUpdateConsignmentSetup]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Create or update Consignment Setup Screen
 ** Date:   31/07/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    31/07/2023   Rajesh Gami     Created
**************************************************************
 EXEC USP_Lot_AddUpdateConsignmentSetup 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_AddUpdateConsignmentSetup] 
@ConsignmentId bigint OUTPUT,
@ConsignmentNumber varchar(100)= null,
@ConsigneeName varchar(100),
@ConsignmentName varchar(100)= null,
@LotId bigint,
@IsRevenue bit = null,
@IsMargin bit = null,
@IsFixedAmount bit= null,
@PercentId bigint= null, 
@PerAmount decimal(10,2)= null,
@MasterCompanyId int,
@CreatedBy varchar(50),
@ConsigneeTypeId int,
@ConsigneeId bigint,
@IsRevenueSplit bit = null,
@ConsignorPercentId bigint= null
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
			   		
		DECLARE @AppModuleId INT = 0;
		DECLARE @AppModuleCustomerId INT = 0;
		DECLARE @AppModuleVendorId INT = 0;
		DECLARE @AppModuleCompanyId INT = 0;
		DECLARE @AppModuleOthersId INT = 0;
		SELECT @AppModuleCustomerId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Customer';
		SELECT @AppModuleVendorId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Vendor';
		SELECT @AppModuleCompanyId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Company';
		SELECT @AppModuleOthersId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Others';

		IF(@ConsigneeTypeId = @AppModuleCustomerId)
		BEGIN
			SET @ConsigneeName = (SELECT [Name] FROM [dbo].[Customer] WITH(NOLOCK) WHERE CustomerId = @ConsigneeId)
		END
		ELSE IF(@ConsigneeTypeId = @AppModuleVendorId)
		BEGIN
			SET @ConsigneeName = (SELECT [VendorName] FROM [dbo].[Vendor] WITH(NOLOCK) WHERE VendorId = @ConsigneeId)
		END
		ELSE IF(@ConsigneeTypeId = @AppModuleCompanyId)
		BEGIN
			SET @ConsigneeName = (SELECT [Name] FROM [dbo].[LegalEntity]  WITH (NOLOCK) WHERE LegalEntityId = @ConsigneeId)
		END

		IF (@ConsignmentId = 0)
		BEGIN
		  INSERT INTO [dbo].[LotConsignment]
            ([ConsignmentNumber],[ConsigneeName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ConsignmentName],[LotId]
            ,[IsRevenue],[IsMargin],[IsFixedAmount],[PercentId],[PerAmount],ConsigneeTypeId,ConsigneeId,IsRevenueSplit,ConsignorPercentId)
		    VALUES
            (@ConsignmentNumber,@ConsigneeName,@MasterCompanyId ,@CreatedBy ,@CreatedBy ,GETUTCDATE(),GETUTCDATE(),1 ,0 ,@ConsignmentName ,@LotId
            ,@IsRevenue ,@IsMargin ,@IsFixedAmount ,@PercentId ,@PerAmount,@ConsigneeTypeId,@ConsigneeId,@IsRevenueSplit,@ConsignorPercentId)
     	    SET @ConsignmentId = SCOPE_IDENTITY();
			--Print @ConsignmentId
			Update DBO.LOT SET ConsignmentId = @ConsignmentId WHERE LotId = @LotId
		END
		ELSE
		BEGIN			
			UPDATE [dbo].[LotConsignment]
			   SET [ConsignmentNumber] = @ConsignmentNumber
			      ,[ConsigneeName] = @ConsigneeName
			      ,[MasterCompanyId] = @MasterCompanyId
			      ,[ConsignmentName] = @ConsignmentName
			      ,[IsRevenue] = @IsRevenue
			      ,[IsMargin] = @IsMargin
				  ,[PercentId] = @PercentId
			      ,[IsFixedAmount] = @IsFixedAmount	
				  ,[PerAmount] = @PerAmount
 			      ,[UpdatedBy] = @CreatedBy			     
			      ,[UpdatedDate] = GETUTCDATE()
				  ,ConsigneeTypeId = @ConsigneeTypeId
				  ,ConsigneeId = @ConsigneeId
				  ,IsRevenueSplit = @IsRevenueSplit
				  ,ConsignorPercentId = @ConsignorPercentId
			 WHERE ConsignmentId = @ConsignmentId; 		 
		END

		Select @ConsignmentId AS ConsignmentId 
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
            ,@AdhocComments varchar(150) = '[USP_Lot_AddUpdateConsignmentSetup]',
            @ProcedureParameters varchar(3000) = '@ConsignmentId = ''' + CAST(ISNULL(@ConsignmentId, '') AS varchar(100))
            + '@ConsignmentNumber = ''' + CAST(ISNULL(@ConsignmentNumber, '') AS varchar(100))
            + '@ConsigneeName = ''' + CAST(ISNULL(@ConsigneeName, '') AS varchar(100))             
            + '@ConsignmentName = ''' + CAST(ISNULL(@ConsignmentName, '') AS varchar(100))
            + '@LotId = ''' + CAST(ISNULL(@LotId, '') AS varchar(100))
            + '@IsRevenue = ''' + CAST(ISNULL(@IsRevenue, '') AS varchar(100))
			+ '@IsMargin = ''' + CAST(ISNULL(@IsMargin, '') AS varchar(100))
			+ '@IsFixedAmount = ''' + CAST(ISNULL(@IsFixedAmount, '') AS varchar(100))
			+ '@PercentId = ''' + CAST(ISNULL(@PercentId, '') AS varchar(100))
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