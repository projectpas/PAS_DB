CREATE FUNCTION [dbo].[GetInternalStatusId]
(
    @InternalStatusId INT = NULL,
    @IsInternalApprove BIT,
    @IsApprovalRule BIT
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
	DECLARE @Pending  INT= 1
    DECLARE @Approved INT= 2
    DECLARE @Rejected INT= 3
    DECLARE @WaitingForApproval INT= 4
	    
    IF ISNULL(@InternalStatusId, 0) = 0
    BEGIN       
        IF @IsApprovalRule = 0
        BEGIN
            SET @Result = @Approved -- Approved 
        END
        ELSE
        BEGIN
            IF @IsInternalApprove = 1
                SET @Result = @Pending; -- Pending
            ELSE
                SET @Result = @Approved; -- Approved
        END
    END
    ELSE
    BEGIN
        SET @Result = @InternalStatusId; -- return existing value
    END

    RETURN @Result;
END