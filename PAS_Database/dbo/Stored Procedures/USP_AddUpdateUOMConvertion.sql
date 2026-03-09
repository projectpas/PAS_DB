/*************************************************************           
 ** File:		          
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To 
 ** Purpose:         
 ** Date:   
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	09-03-2026           Nakul Chandigra     Created 

	
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateUOMConvertion]
@tblType_UOMConvertion UOMConvertionType READONLY,
@UOMConversionId BIGINT,
@IsError BIT OUTPUT
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

SET @IsError = 0;

SELECT [UOMConversionId],
       [FromUOM],
       [ToUOM],
       [Factor],
       [CreatedBy],
       [CreatedDate],
       [UpdatedBy],
       [UpdatedDate],
       [IsActive],
       [IsDeleted],
       [MasterCompanyId]
INTO #ColumnData
FROM @tblType_UOMConvertion

IF (@UOMConversionId IS NOT NULL AND @UOMConversionId > 0)
BEGIN

    IF EXISTS (
        SELECT 1
        FROM dbo.UOMConversion T WITH(NOLOCK)
        INNER JOIN #ColumnData C
        ON T.FromUOM = C.FromUOM
        AND T.ToUOM = C.ToUOM
        AND T.Factor = C.Factor
        AND T.UOMConversionId <> @UOMConversionId
        AND T.MasterCompanyId = C.MasterCompanyId
    )
    BEGIN
        SET @IsError = 1
    END
    ELSE
    BEGIN

        UPDATE T
        SET
            T.FromUOM       = C.FromUOM,
            T.ToUOM         = C.ToUOM,
            T.Factor        = C.Factor,
            T.UpdatedBy     = C.UpdatedBy,
            T.UpdatedDate   = GETUTCDATE()
        FROM dbo.UOMConversion T
        INNER JOIN #ColumnData C
        ON T.UOMConversionId = @UOMConversionId

    END
END
ELSE
BEGIN

    IF EXISTS (
        SELECT 1
        FROM dbo.UOMConversion T WITH(NOLOCK)
        INNER JOIN #ColumnData C
        ON T.FromUOM = C.FromUOM
        AND T.ToUOM = C.ToUOM
        AND T.MasterCompanyId = C.MasterCompanyId
    )
    BEGIN
        SET @IsError = 1
    END
    ELSE
    BEGIN

        INSERT INTO dbo.UOMConversion
        (
            [FromUOM],
            [ToUOM],
            [Factor],
            [IsMultiply],
            [CreatedBy],
            [DecimalPlaces],
            [CreatedDate],
            [UpdatedBy],
            [UpdatedDate],
            [IsActive],
            [IsDeleted],
            [MasterCompanyId]
        )
        SELECT
            [FromUOM],
            [ToUOM],
            [Factor],
            1,
            [CreatedBy],
            6,
            GETUTCDATE(),
            [UpdatedBy],
            GETUTCDATE(),
            [IsActive],
            [IsDeleted],
            [MasterCompanyId]
        FROM #ColumnData

    END
END

END TRY

BEGIN CATCH
IF @@trancount > 0		  
	ROLLBACK TRAN;  
	DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_AddUpdateUOMConvertion]'
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName
		,@AdhocComments = @AdhocComments
		,@ProcedureParameters = @ProcedureParameters
		,@ApplicationName = @ApplicationName
		,@ErrorLogID = @ErrorLogID OUTPUT;

	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
	RETURN (1); 
END CATCH
END