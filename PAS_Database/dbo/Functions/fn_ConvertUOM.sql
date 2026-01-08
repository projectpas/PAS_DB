
/****************************************************************************************************************************************************************************/

/****** Object:  UserDefinedFunction [dbo].[fn_ConvertUOM]    Script Date: 12/2/2025 3:39:07 PM ******/
CREATE   FUNCTION [dbo].[fn_ConvertUOM]
(    
    @Qty        DECIMAL(18,8),
    @FromUOM    VARCHAR(50),
    @ToUOM      VARCHAR(50),
    @IsCost     BIT = 0,
	@MasterCompanyId INT 
)
RETURNS DECIMAL(18,6)
AS
BEGIN
	-- Same UOM Return Same Qty / Cost
	IF(@MasterCompanyId IS NULL OR @MasterCompanyId =0)
	BEGIN
		SET @MasterCompanyId = (SELECT TOP 1 MasterCompanyId FROM dbo.MasterCompany WITH(NOLOCK) WHERE ISNULL(IsActive,0) = 1)
	END

    IF(@FromUOM = @ToUOM)
	BEGIN
		RETURN ROUND(@Qty, 6);
	END
	
	DECLARE @Factor DECIMAL(18,8), @IsMultiply BIT = 0;
	    -- Case 1: Exact From → To conversion exists
    SELECT @Factor = Factor, @IsMultiply = IsMultiply
    FROM dbo.UOMConversion WITH (NOLOCK)
    WHERE FromUOM = @FromUOM
      AND ToUOM   = @ToUOM
	  AND MasterCompanyId = @MasterCompanyId;

    IF (@IsCost = 1)
    BEGIN
        IF (@Factor IS NOT NULL)
        BEGIN
            IF (@IsMultiply = 1)
                RETURN ROUND(@Qty / @Factor, 6);
            ELSE
                RETURN ROUND(@Qty * @Factor, 6);
        END

        -- Reverse conversion
        SELECT @Factor = Factor, @IsMultiply = IsMultiply
        FROM dbo.UOMConversion WITH (NOLOCK)
        WHERE FromUOM = @ToUOM
          AND ToUOM   = @FromUOM AND MasterCompanyId = @MasterCompanyId;

        IF (@Factor IS NOT NULL)
        BEGIN
            IF (@IsMultiply = 1)
                RETURN ROUND(@Qty / @Factor, 6);
            ELSE
                RETURN ROUND(@Qty * @Factor, 6);
        END
    END
    ELSE
    BEGIN
        -- Quantity conversion
        IF (@Factor IS NOT NULL)
            RETURN ROUND(@Qty * @Factor, 6);

        SELECT @Factor = Factor
        FROM dbo.UOMConversion WITH (NOLOCK)
        WHERE FromUOM = @ToUOM
          AND ToUOM   = @FromUOM AND MasterCompanyId = @MasterCompanyId;

        IF (@Factor IS NOT NULL)
            RETURN ROUND(@Qty / @Factor, 6);
    END

    -- No conversion found
    RETURN ROUND(@Qty, 6);
END


--CREATE OR ALTER   FUNCTION [dbo].[fn_ConvertUOM]
--(    
--    @Qty        DECIMAL(18,6),
--    @FromUOM    VARCHAR(50),
--    @ToUOM      VARCHAR(50),
--	@IsCost    BIT = 0
--)
--RETURNS DECIMAL(18,6)
--AS
--BEGIN
--    DECLARE @Factor DECIMAL(18,6), @IsMultiply BIT =0;

--    -- Case 1: Exact From → To conversion exists
--    SELECT @Factor = factor, @IsMultiply = IsMultiply
--    FROM [dbo].[UOMConversion] WITH(NOLOCK)
--    WHERE FromUOM = @FromUOM
--      AND ToUOM   = @ToUOM;

--	IF(@IsCost = 1)
--	BEGIN
--		IF(@IsMultiply = 1)
--		BEGIN
--			IF (@Factor IS NOT NULL)
--			RETURN @Qty / @Factor;
--		END
--		ELSE
--		BEGIN
--			IF (@Factor IS NOT NULL)
--			RETURN @Qty * @Factor;
--		END 

--		SELECT @Factor = factor ,@IsMultiply = IsMultiply
--		FROM [dbo].[UOMConversion] WITH(NOLOCK)
--		WHERE FromUOM = @ToUOM
--		  AND ToUOM   = @FromUOM;

--		IF(@IsMultiply = 1)
--		BEGIN
--			IF (@Factor IS NOT NULL)
--			RETURN @Qty / @Factor;
--		END
--		ELSE
--		BEGIN
--			IF (@Factor IS NOT NULL)
--			RETURN @Qty * @Factor;
--		END 
--	END
--	ELSE 
--	BEGIN -- For the QTY
--		IF (@Factor IS NOT NULL)
--			RETURN @Qty * @Factor;

--		-- Case 2: Reverse conversion exists (To → From)
--		SELECT @Factor = factor
--		FROM [dbo].[UOMConversion] WITH(NOLOCK)
--		WHERE FromUOM = @ToUOM
--		  AND ToUOM   = @FromUOM;

--		IF (@Factor IS NOT NULL)
--			RETURN @Qty / @Factor;
--	END

--    -- Case 3: No conversion found - return original qty
--    RETURN @Qty;
--END
/****************************************************************************************************************************************************************************/

--EXEC sp_help 'Stockline';
--EXEC sp_help 'StocklineAudit';