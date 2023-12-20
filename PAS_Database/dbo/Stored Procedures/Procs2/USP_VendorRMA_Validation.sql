
/*************************************************************           
 ** File:   [USP_VendorRMA_Validation]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Check RMA NumberExist OR Not
 ** Date:   07/04/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    07/04/2023   Moin Bloch     Created
*******************************************************************************
   EXEC [dbo].[USP_VendorRMA_Validation] 0,1287,212111,1
*******************************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorRMA_Validation] 
@VendorRMAId BIGINT,
@VendorId BIGINT,
@RMANumber VARCHAR(50),
@MasterCompanyId INT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY    

		IF OBJECT_ID(N'tempdb..#tmpExistVendorRMA') IS NOT NULL
		BEGIN
			DROP TABLE #tmpExistVendorRMA
		END

		CREATE TABLE #tmpExistVendorRMA  
		( 		  
		  [RMANum] varchar(100) NULL,
		  [VendorRMAStatus] varchar(50) NULL,
		  [CreatedDate] DATETIME2(7) NULL,
		  [CreatedBy] varchar(100) NULL
		)

		IF EXISTS (SELECT [RMANumber] FROM [dbo].[VendorRMA] WITH (NOLOCK) WHERE [RMANumber] = @RMANumber AND  [VendorId] = @VendorId AND ([VendorRMAId] = 0 OR [VendorRMAId] <> @VendorRMAId) AND [MasterCompanyId] = @MasterCompanyId)
		BEGIN
			INSERT INTO #tmpExistVendorRMA ([RMANum],[VendorRMAStatus],[CreatedDate],[CreatedBy])
					SELECT TOP 1 VD.[RMANumber],VS.[StatusName],VD.[CreatedDate],VD.[CreatedBy] FROM 					
					[dbo].[VendorRMA] VD WITH(NOLOCK) 
					INNER JOIN [dbo].[VendorRMAHeaderStatus] VS WITH(NOLOCK) ON VD.[VendorRMAStatusId] = VS.[VendorRMAStatusId]
					WHERE VD.[RMANumber] = @RMANumber 
					  AND VD.[MasterCompanyId] = @MasterCompanyId;			
		END
		SELECT * FROM #tmpExistVendorRMA;
				
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'			
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_VendorRMA_Validation]'			
			,@ProcedureParameters VARCHAR(3000) = '@VendorRMAId = ''' + CAST(ISNULL(1,'') AS varchar(100))				 
            ,@ApplicationName varchar(100) = 'PAS'
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