/*************************************************************           
 ** File:   [USP_VendorRMA_CheckRMANumberExists]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Check RMA NumberExist OR Not
 ** Date:   07/03/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    07/03/2023   Moin Bloch     Created
*******************************************************************************
*******************************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorRMA_CheckRMANumberExists] 
@VendorRMADetail VendorRMADetailType READONLY,
@MasterCompanyId INT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY    
	    DECLARE @MasterLoopID AS INT;
		DECLARE @RMANum VARCHAR(50);
		DECLARE @VendorRMAId AS BIGINT;
				
		IF OBJECT_ID(N'tempdb..#tmpExistVendorRMA') IS NOT NULL
		BEGIN
			DROP TABLE #tmpExistVendorRMA
		END
		IF OBJECT_ID(N'tempdb..#RMAvalidation') IS NOT NULL
		BEGIN
			DROP TABLE #RMAvalidation
		END
				    
		CREATE TABLE #tmpExistVendorRMA  
		( 		  
		  [RMANum] varchar(100) NULL,
		  [VendorRMAStatus] varchar(50) NULL,
		  [CreatedDate] DATETIME2(7) NULL,
		  [CreatedBy] varchar(100) NULL
		)

		CREATE TABLE #RMAvalidation 
		(
			[ID] BIGINT NOT NULL IDENTITY, 
			[VendorRMAId] BIGINT NULL,
			[RMANum] varchar(100) NULL			
		)

		INSERT INTO #RMAvalidation ([VendorRMAId],[RMANum])
		SELECT [VendorRMAId],[RMANum] FROM @VendorRMADetail WHERE [VendorRMADetailId] = 0;

		SELECT @MasterLoopID = MAX(ID) FROM #RMAvalidation;
		WHILE (@MasterLoopID > 0)
		BEGIN
			SELECT @RMANum = [RMANum],@VendorRMAId = [VendorRMAId] FROM #RMAvalidation WHERE ID  = @MasterLoopID;

			IF EXISTS (SELECT 1 FROM [dbo].[VendorRMADetail] WITH(NOLOCK) WHERE [RMANum] = @RMANum AND ([VendorRMAId] = 0 OR [VendorRMAId] <> @VendorRMAId) AND [MasterCompanyId] = @MasterCompanyId)
			BEGIN
					INSERT INTO #tmpExistVendorRMA ([RMANum],[VendorRMAStatus],[CreatedDate],[CreatedBy])
					SELECT TOP 1 VD.[RMANum],VS.[VendorRMAStatus],VD.[CreatedDate],VD.[CreatedBy] FROM [dbo].[VendorRMADetail] VD WITH(NOLOCK) 
					INNER JOIN [dbo].[VendorRMAStatus] VS WITH(NOLOCK) ON VD.[VendorRMAStatusId] = VS.[VendorRMAStatusId]
					WHERE VD.[RMANum] = @RMANum 
					  AND VD.[MasterCompanyId] = @MasterCompanyId;
			END	
			SET @MasterLoopID = @MasterLoopID - 1;
		END
		SELECT * FROM #tmpExistVendorRMA;
				
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'			
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_VendorRMA_CheckRMANumberExists]'			
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