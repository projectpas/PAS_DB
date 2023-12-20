CREATE   FUNCTION [dbo].[udfGetLFByLFId] (
    @lfID INT
)
RETURNS TABLE
AS
RETURN
    SELECT 
		LF.LeafNodeId
        FROM
		dbo.LeafNode LF WITH (NOLOCK)
		WHERE
        ParentId = @lfID
		AND  IsActive = 1 and IsDeleted = 0