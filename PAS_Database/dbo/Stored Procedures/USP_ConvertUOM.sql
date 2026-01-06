/*************************************************************           
 ** File:   [USP_ConvertUOM]           
 ** Author:  Moin Bloch
 ** Description: 
 ** Purpose:         
 ** Date:        
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/01/2026  Moin Bloch    Created

-- EXEC [dbo].[USP_ConvertUOM] 1070.000000,'Ltr','Ml',1,0
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_ConvertUOM]
@Qty        DECIMAL(18,8),
@FromUOM    VARCHAR(50),
@ToUOM      VARCHAR(50),
@IsCost     BIT = 0,
@Result     DECIMAL(18,6) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
      
    -- Same UOM → return same Qty / Cost
    IF (@FromUOM = @ToUOM)
    BEGIN
        SET @Result = ROUND(@Qty, 6);
        RETURN;
    END;

    DECLARE @Factor DECIMAL(18,8)=0,@IsMultiply BIT = 0;

    /*-----------------------------------------
      Case 1: Exact From → To conversion
    ------------------------------------------*/
    SELECT @Factor = Factor,@IsMultiply = IsMultiply FROM [dbo].[UOMConversion] WITH(NOLOCK) WHERE [FromUOM] = @FromUOM AND [ToUOM] = @ToUOM;
    /*-----------------------------------------
      COST Conversion
    ------------------------------------------*/
    IF (@IsCost = 1)
    BEGIN
        IF (@Factor > 0)
        BEGIN
            IF (@IsMultiply = 1)
                SET @Result = ROUND(@Qty / @Factor, 6);
            ELSE
                SET @Result = ROUND(@Qty * @Factor, 6);				
			RETURN; 
        END;
		--PRINT @Result
        -- Reverse conversion
        SELECT @Factor = [Factor], @IsMultiply = [IsMultiply] FROM [dbo].[UOMConversion] WITH(NOLOCK) WHERE [FromUOM] = @ToUOM AND [ToUOM] = @FromUOM;

        IF (@Factor > 0)
        BEGIN
            IF (@IsMultiply = 1)
                SET @Result = ROUND(@Qty / @Factor, 6);
            ELSE
                SET @Result = ROUND(@Qty * @Factor, 6);

            RETURN;
        END;
    END
    ELSE
    BEGIN
        /*-----------------------------------------
          QUANTITY Conversion
        ------------------------------------------*/
        IF (@Factor > 0)
        BEGIN
            SET @Result = ROUND(@Qty * @Factor, 6);
            RETURN;
        END;

        -- Reverse conversion
        SELECT @Factor = Factor FROM [dbo].[UOMConversion] WITH (NOLOCK) WHERE [FromUOM] = @ToUOM AND [ToUOM] = @FromUOM;

        IF (@Factor > 0)
        BEGIN
            SET @Result = ROUND(@Qty / @Factor, 6);
            RETURN;
        END;
    END;

    -- No conversion found
    SET @Result = ROUND(@Qty, 6);

	
  END TRY
  BEGIN CATCH
  SELECT
    ERROR_NUMBER() AS ErrorNumber, ERROR_STATE() AS ErrorState, ERROR_SEVERITY() AS ErrorSeverity, ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,ERROR_MESSAGE() AS ErrorMessage;
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_ConvertUOM]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Qty, '') AS VARCHAR(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END